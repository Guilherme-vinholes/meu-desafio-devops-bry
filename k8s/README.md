# Kubernetes — Manifests e Helm

Tudo que roda dentro do cluster K3s após provisionamento (Terraform) e configuração (Ansible).

- `base/` — Namespace, Deployments/Services da API (3 réplicas) e do frontend (2 réplicas), via Kustomize
- `ingress/` — Nginx Ingress Controller (Helm) e a regra de roteamento da aplicação
- `cert-manager/` — cert-manager (Helm) + ClusterIssuer para emissão automática via Let's Encrypt
- `monitoring/` — Prometheus + Grafana (`kube-prometheus-stack`, Helm), Grafana sem exposição pública

## Ordem de instalação

1. `ingress/` — o Ingress Controller precisa existir antes do cert-manager conseguir resolver o desafio HTTP-01
2. `cert-manager/` — ClusterIssuer
3. `base/` — `kubectl apply -k base/`, mais o `api-secret.yaml` (gerado a partir do `.example`, nunca commitado) aplicado à parte
4. `ingress/ingress.yaml` — regra de roteamento + TLS (depende de 1 e 2 já estarem prontos, e do DNS do domínio já apontar para o cluster)
5. `monitoring/` — pode ser instalado em qualquer momento, é independente da aplicação

Cada subpasta tem seu próprio `README.md` com o comando exato de instalação.
