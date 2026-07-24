# ADR 0002 — Manifests Kubernetes: aplicação, Ingress, TLS e monitoramento

## Contexto

Com a infraestrutura (Terraform, bry-004) e o cluster K3s (Ansible, bry-005) definidos em
código, esta etapa define o que roda dentro do cluster: a aplicação em si, o roteamento
HTTP(S), o certificado TLS automático e o monitoramento.

## Decisões

- **Terceiros via Helm, aplicação via manifests próprios**: `ingress-nginx`, `cert-manager`
  e `kube-prometheus-stack` são instalados pelos charts oficiais (com `values.yaml` de
  override neste repo). Reescrever esses componentes como YAML puro seria redundante,
  mais propenso a erro, e não é como esses projetos esperam ser consumidos. Só a
  aplicação (`api`/`frontend`) e a regra de roteamento (`Ingress`) têm manifests
  hand-written, porque são específicos deste projeto.
- **`type: LoadBalancer` sem ELB da AWS**: o K3s já vem com o ServiceLB (klipper-lb)
  habilitado (o Ansible desabilitou só o Traefik) — ele expõe portas 80/443 diretamente
  nos IPs públicos dos nodes quando um Service é `LoadBalancer`, sem precisar provisionar
  um Elastic Load Balancer real. Evita custo e complexidade adicional do Terraform.
- **Ingress só roteia para o `frontend`**: o Nginx do frontend (bry-003) já faz o proxy
  interno de `/api/*` para o Service `api`. Duplicar essa lógica de roteamento no Ingress
  não traria benefício e criaria dois lugares para manter a mesma regra.
- **HTTP-01 em vez de DNS-01 para o Let's Encrypt**: mais simples de configurar (não
  depende de credenciais de API do provedor de DNS), suficiente porque o Ingress já está
  publicamente acessível na porta 80.
- **`api-secret.yaml` nunca commitado**: segue o mesmo padrão de `terraform.tfvars` e
  `hosts.ini` — só o `.example` fica no repositório; a `DATABASE_URL` real (apontando
  para o RDS) é aplicada manualmente com `kubectl apply -f`.
- **Grafana sem exposição pública**: acesso só via `kubectl port-forward`, coerente com
  a decisão de segurança do ADR 0001 (nenhum serviço interno de observabilidade exposto
  à Internet).
- **kube-prometheus-stack com `kubeEtcd`/`kubeControllerManager`/`kubeScheduler`
  desabilitados**: o K3s embute o control-plane de um jeito que não expõe essas métricas
  do jeito que o chart (pensado para kubeadm) espera — deixá-los ligados só gera alvos de
  scrape permanentemente down.
- **`alertmanager` habilitado** (revertido no hotfix `1.0.2`, ver Release Notes):
  inicialmente desligado por economia de memória nas instâncias pequenas, mas
  "monitoramento e alertas" é item explícito do desafio, não bônus — religado com o
  receiver `null` default do chart (avalia e recebe os alertas do Prometheus, mas não
  notifica ninguém, já que nenhum canal — Slack/e-mail/PagerDuty — está disponível
  neste ambiente). Trocar o receiver por um real é mudança de `values.yaml`, não de
  arquitetura.
- **HorizontalPodAutoscaler em `api` e `frontend`** (adicionado no hotfix `1.0.2`):
  usa o metrics-server já embutido no K3s (nenhuma instalação extra necessária).
  `minReplicas` mantém o piso de HA de cada Deployment; escala por utilização de CPU
  (`averageUtilization: 70`), já que os `resources.requests.cpu` necessários para o
  HPA calcular a métrica já existiam nos Deployments desde o bry-006.

## Consequências

- A aplicação exige que a imagem já esteja publicada no GitHub Container Registry
  (`ghcr.io/guilherme-vinholes/meu-desafio-devops-bry-{api,frontend}`) — isso é
  responsabilidade do CI/CD (bry-007, ainda não implementado). Até lá, os Deployments
  não sobem com sucesso num cluster real.
- O domínio usado no `Ingress`/`ClusterIssuer` precisa ser real e ter o DNS apontando
  para o IP público de um node antes de aplicar — nenhum desses manifests foi testado
  contra um cluster de verdade nesta sessão (nenhuma ferramenta k8s está instalada
  nesta máquina).
