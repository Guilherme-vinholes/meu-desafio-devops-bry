# Terraform — Provisionamento AWS

Responsável por criar a infraestrutura na AWS: VPC, subnets, Security Groups, instâncias EC2 (cluster K3s) e RDS PostgreSQL.

- `modules/` — módulos reutilizáveis (network, compute, database, security)
- `environments/` — configuração específica por ambiente (ex: `prod/`)

Ansible entra depois do Terraform para configurar o que foi provisionado (ver `infra/ansible/`).
