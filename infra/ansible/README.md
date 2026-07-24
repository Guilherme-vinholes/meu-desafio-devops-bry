# Ansible — Configuração dos Servidores

Responsável por configurar as instâncias EC2 já provisionadas pelo Terraform: instalação de Docker, K3s (master/workers) e dependências do sistema.

- `inventories/prod/hosts.ini` — inventário dos hosts (gerado a partir do output do Terraform, gitignored — veja `hosts.ini.example`)
- `roles/hardening` — ufw (firewall local, defesa em profundidade além do Security Group), fail2ban, unattended-upgrades, desabilita login root/senha por SSH
- `roles/docker` — instala Docker Engine a partir do repositório oficial
- `roles/k3s-master` — instala o control-plane do K3s (sem Traefik, já que o Nginx Ingress é instalado à parte), expõe o node-token e busca o kubeconfig
- `roles/k3s-worker` — instala o agente K3s e conecta ao master via IP privado, usando o token gerado pelo master

## Uso

```bash
# 1. Instalar as collections necessarias (community.general, usada pelo role hardening)
ansible-galaxy collection install -r requirements.yml

# 2. Gerar o inventario a partir dos outputs do Terraform (requer terraform + jq)
../../scripts/generate-inventory.sh

# 3. Rodar o playbook
ansible-playbook site.yml
```

O kubeconfig do cluster é copiado para `kubeconfig-prod.yaml` na raiz do repo (gitignored)
ao final da role `k3s-master`.
