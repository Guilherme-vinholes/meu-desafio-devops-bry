# Runbook — Deploy completo (do zero até HTTPS funcionando)

Guia único, passo a passo, do primeiro `terraform apply` até o site respondendo em
produção com certificado válido. Cada etapa referencia o `README.md` da pasta
correspondente para detalhes — aqui é só a ordem certa e os comandos exatos.

Pré-requisitos: conta AWS com credenciais configuradas (`aws configure` ou variáveis
`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`), `terraform` >= 1.6, `ansible` +
`ansible-lint` (ou Docker, ver `infra/ansible/README.md`), `kubectl`, `helm`, um par de
chaves SSH, e um domínio próprio com acesso ao painel de DNS.

## 1. Provisionar a infraestrutura (Terraform)

```bash
cd infra/terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
# preencha admin_cidr (seu IP/32), ssh_public_key, db_password
terraform init
terraform plan   # confira o que vai ser criado antes de aplicar
terraform apply
```

Isso cria recursos reais e cobráveis na AWS (ver `docs/adr/0001-infraestrutura-aws-k3s.md`
para o detalhamento de custo). Anote os outputs (`master_public_ip`, `worker_public_ips`,
`db_endpoint`) — os próximos passos dependem deles.

## 2. Configurar os servidores (Ansible)

```bash
cd ../../../..  # volta pra raiz do repo
./scripts/generate-inventory.sh   # gera infra/ansible/inventories/prod/hosts.ini a partir do terraform output
cd infra/ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
```

Ao final, `kubeconfig-prod.yaml` aparece na raiz do repo, já apontando para o IP público
do master. Confirme o cluster de pé:

```bash
export KUBECONFIG=$(pwd)/../../kubeconfig-prod.yaml   # a partir de infra/ansible
kubectl get nodes   # espera-se 1 master + 2 workers, todos Ready
```

## 3. Ingress Controller

```bash
cd ../../k8s/ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  -f values-ingress-nginx.yaml
kubectl get svc -n ingress-nginx   # o EXTERNAL-IP do ServiceLB deve ser o(s) IP(s) publico(s) dos nodes
```

## 4. DNS

Aponte um registro A do seu domínio (ex: `assinatura.seudominio.com.br`) para o
`master_public_ip` (ou qualquer worker) do passo 1. Sem isso, o desafio HTTP-01 do
cert-manager falha no passo 5, e o `Ingress` do passo 6 não tem para onde apontar.

## 5. cert-manager

```bash
cd ../cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true
# edite cluster-issuer.yaml: troque o e-mail
kubectl apply -f cluster-issuer.yaml
```

## 6. Aplicação (API + frontend)

```bash
cd ../base
cp api-secret.example.yaml api-secret.yaml
# edite api-secret.yaml: DATABASE_URL com o db_endpoint do passo 1 + a senha do terraform.tfvars
kubectl apply -k .
kubectl apply -f api-secret.yaml
kubectl -n bry-desafio get pods   # espera-se 3 api + 2 frontend, todos Running
```

## 7. Ingress da aplicação (rota + TLS)

```bash
cd ../ingress
# edite ingress.yaml: troque assinatura.SEUDOMINIO.com.br pelo dominio do passo 4
kubectl apply -f ingress.yaml
kubectl -n bry-desafio get certificate   # aguarde READY=True (pode levar 1-2 min)
```

## 8. Monitoramento (opcional, independente dos passos acima)

```bash
cd ../monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f values-kube-prometheus-stack.yaml \
  --set grafana.adminPassword="<defina-uma-senha>"
```

## 9. Smoke test

```bash
./scripts/smoke-test.sh assinatura.seudominio.com.br
```

Confere: frontend respondendo em HTTPS, certificado válido, `POST /api/sign` e
`GET /api/signatures` funcionando através do domínio público, e (se `KUBECONFIG`
estiver setado) a contagem de réplicas da API confirmando a HA.

## Troubleshooting comum

- **`terraform apply` falha em `aws_key_pair`**: `ssh_public_key` no `terraform.tfvars`
  provavelmente está vazio ou mal formatado — precisa ser o conteúdo completo de um
  `.pub` (`ssh-ed25519 AAAA...`), não o caminho do arquivo.
- **Ansible não conecta via SSH**: confirme que `admin_cidr` no Terraform é mesmo o seu
  IP público atual (ele muda se você trocar de rede) — o Security Group `ssh` só libera
  esse IP específico.
- **`Certificate` fica `READY=False` por mais de alguns minutos**: geralmente é DNS
  ainda não propagado (passo 4) ou o Ingress Controller ainda sem `EXTERNAL-IP`
  (passo 3) — confirme os dois antes de suspeitar do cert-manager em si.
- **Pods da `api` em `ImagePullBackOff`**: os pacotes do GHCR nascem privados (ver
  `docs/adr/0003-cicd-github-actions.md`) — marque-os como públicos nas configurações
  do pacote no GitHub, ou crie um `imagePullSecrets`.

## Desprovisionar (evitar custo contínuo)

Ordem inversa: remova os releases Helm e os recursos do namespace `bry-desafio`
primeiro (senão o `terraform destroy` não afeta eles, mas as instâncias EC2 somem com
o cluster junto, então não faz diferença prática — pode ir direto ao Terraform):

```bash
cd infra/terraform/environments/prod
terraform destroy
```
