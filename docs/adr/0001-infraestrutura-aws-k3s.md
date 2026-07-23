# ADR 0001 — Infraestrutura AWS para o cluster K3s

## Contexto

O desafio exige um serviço web em container, com alta disponibilidade como diferencial
("Kubernetes gerenciado ou similar"), infraestrutura protegida contra acesso não
autorizado, HTTPS, e máximo uso de IaC.

## Decisões

- **K3s em vez de kubeadm vanilla**: instâncias EC2 `t3.small`/`t3.micro` têm pouca
  memória para rodar um control-plane kubeadm completo + kube-prometheus-stack de forma
  estável. K3s é mais leve e está explicitamente permitido pelo enunciado do desafio.
- **Topologia 1 master + 2 workers**: satisfaz o requisito de alta disponibilidade
  (múltiplos workers), sem pagar o custo de HA no control-plane (múltiplos masters com
  etcd distribuído), que seria desproporcional ao escopo do desafio.
- **RDS PostgreSQL em vez de Postgres dentro do cluster**: banco gerenciado remove a
  necessidade de PersistentVolumes/StatefulSets no K3s para o desafio, e reflete uma
  prática comum em produção (separar estado do cluster de aplicação).
- **Subnets públicas para EC2, privadas para RDS**: as instâncias do cluster precisam de
  IP público para o Ingress receber tráfego HTTP/HTTPS diretamente; o RDS não precisa
  ser alcançável da Internet, então fica isolado em subnet privada.
- **Sem NAT Gateway**: as instâncias públicas já têm rota direta à Internet via
  Internet Gateway; um NAT Gateway só seria necessário para egress de subnets privadas,
  que neste desenho não precisam de acesso à Internet. Evita custo (~US$0,045/h + dados)
  sem abrir mão de segurança.
- **Security Groups segmentados**:
  - `web`: 80/443 públicos (Ingress do cluster).
  - `ssh`: 22 restrito a um único IP/32 (o do administrador) — nunca `0.0.0.0/0`.
  - `cluster_internal`: portas do K3s (6443 API server, 10250 kubelet, 8472 VXLAN do
    Flannel) liberadas apenas entre instâncias que possuem esse mesmo SG (regra
    auto-referenciada) — nunca expostas publicamente.
  - `db`: 5432 liberado somente para o SG do cluster, nunca público.
- **IAM mínimo por instância**: role com a policy gerenciada `AmazonSSMManagedInstanceCore`,
  permitindo acesso operacional via SSM Session Manager como alternativa ao SSH, sem abrir
  portas ou permissões adicionais.
- **Estado do Terraform local (não remoto)**: para o escopo do desafio, manter um backend
  S3+DynamoDB adicionaria um passo de bootstrap (criar bucket/tabela antes do primeiro
  `terraform init`) sem benefício prático em um projeto de avaliação de pessoa única.
  Documentado aqui como possível próxima melhoria, não implementado.
- **`terraform apply` nunca é executado automaticamente**: por criar recursos reais e
  cobráveis na AWS, é uma ação manual do responsável pelo projeto, feita com suas próprias
  credenciais — não faz parte de nenhum pipeline automático neste repositório.

## Consequências

- Custo mensal estimado limitado a: 3x EC2 (t3.small + 2x t3.micro), 1x RDS
  `db.t3.micro`, sem NAT Gateway. Fora do free tier após ~10 dias rodando 24/7 (free tier
  de 750h/mês é compartilhado entre todas as instâncias t2/t3.micro da conta).
- Ansible (próxima etapa) consome os outputs deste Terraform (`master_public_ip`,
  `worker_public_ips`, `db_endpoint`) para montar o inventário e configurar o K3s.
