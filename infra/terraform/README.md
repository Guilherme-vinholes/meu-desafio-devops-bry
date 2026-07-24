# Terraform — Provisionamento AWS

Responsável por criar a infraestrutura na AWS: VPC, subnets, Security Groups, instâncias EC2 (cluster K3s) e RDS PostgreSQL.

- `modules/network` — VPC, subnets públicas (EC2) e privadas (RDS), Internet Gateway, route tables
- `modules/security` — Security Groups: `web` (80/443 públicos), `ssh` (22 restrito ao IP do admin), `cluster_internal` (auto-referenciado, portas do K3s nunca públicas), `db` (Postgres só a partir do cluster)
- `modules/compute` — 1 instância master + N workers (K3s), AMI Ubuntu 22.04, IAM role com SSM, key pair a partir de uma chave pública fornecida
- `modules/database` — RDS PostgreSQL em subnet privada, sem IP público
- `environments/prod` — liga os módulos acima; copie `terraform.tfvars.example` para `terraform.tfvars` (gitignored) antes de rodar

## Uso

```bash
cd infra/terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars   # preencha admin_cidr, ssh_public_key, db_password
terraform init
terraform plan
terraform apply
```

`terraform apply` cria recursos reais e cobráveis na AWS — rode manualmente, com suas próprias
credenciais, quando estiver pronto para provisionar. Nunca foi executado automaticamente por CI/agente.

## Validação automática

`.github/workflows/iac-validate.yml` roda `terraform fmt -check` + `terraform validate`
(sem credenciais AWS) a cada PR/push que toque `infra/**`, junto com `ansible-lint` e
`kubeconform` nos manifests k8s — ver `docs/adr/0003-cicd-github-actions.md`.

Ansible entra depois do Terraform para configurar o que foi provisionado (ver `infra/ansible/`),
usando os outputs (`master_public_ip`, `worker_public_ips`, `db_endpoint`) para montar o inventário.
