# Ansible — Configuração dos Servidores

Responsável por configurar as instâncias EC2 já provisionadas pelo Terraform: instalação de Docker, K3s (master/workers) e dependências do sistema.

- `inventories/` — inventário dos hosts (gerado a partir do output do Terraform)
- `roles/` — roles de configuração (docker, k3s-master, k3s-worker, hardening)
