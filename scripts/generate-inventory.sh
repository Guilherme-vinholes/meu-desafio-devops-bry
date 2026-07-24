#!/usr/bin/env bash
# Gera infra/ansible/inventories/prod/hosts.ini a partir do `terraform output`
# do ambiente prod. Requer terraform e jq instalados, e que `terraform apply`
# ja tenha sido rodado manualmente (este script nunca aplica infraestrutura).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/infra/terraform/environments/prod"
INVENTORY="$ROOT_DIR/infra/ansible/inventories/prod/hosts.ini"

master_ip=$(terraform -chdir="$TF_DIR" output -raw master_public_ip)
worker_ips=$(terraform -chdir="$TF_DIR" output -json worker_public_ips | jq -r '.[]')

ssh_key="${SSH_PRIVATE_KEY:-~/.ssh/id_ed25519}"

{
  echo "[k3s_master]"
  echo "$master_ip ansible_user=ubuntu ansible_ssh_private_key_file=$ssh_key"
  echo ""
  echo "[k3s_workers]"
  while IFS= read -r ip; do
    echo "$ip ansible_user=ubuntu ansible_ssh_private_key_file=$ssh_key"
  done <<< "$worker_ips"
  echo ""
  echo "[k3s_cluster:children]"
  echo "k3s_master"
  echo "k3s_workers"
} > "$INVENTORY"

echo "Inventario gerado em $INVENTORY"
