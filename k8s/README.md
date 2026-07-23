# Kubernetes — Manifests e Helm

Tudo que roda dentro do cluster K3s após provisionamento (Terraform) e configuração (Ansible).

- `base/` — Deployments e Services da API e do frontend
- `ingress/` — Nginx Ingress Controller (proxy reverso) e regras de roteamento
- `cert-manager/` — Emissão automática de certificados Let's Encrypt
- `monitoring/` — Prometheus + Grafana (kube-prometheus-stack)
