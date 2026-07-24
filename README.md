# meu-desafio-devops-bry
Solução automatizada do desafio técnico para Analista de DevOps (Júnior/Pleno). Contém respostas da etapa teórica e provisionamento de cluster Kubernetes (K3s) em Alta Disponibilidade na nuvem AWS, com aplicação em Go, Proxy Reverso Nginx, SSL automático via Cert-Manager/Let's Encrypt e monitoramento com Prometheus e Grafana.

## Visão geral

API em Go que simula a assinatura digital de documentos, com uma interface web simples para acionar a assinatura, rodando em um cluster Kubernetes (K3s) de alta disponibilidade (1 master + 2 workers) provisionado na AWS.

## Stack

| Camada | Ferramenta |
|---|---|
| Aplicação | Go (API) + interface web |
| Provisionamento de infraestrutura | Terraform |
| Configuração dos servidores | Ansible |
| Orquestração de containers | Kubernetes (K3s) |
| Proxy reverso / Ingress | Nginx Ingress Controller |
| Certificado SSL | cert-manager + Let's Encrypt |
| Banco de dados | PostgreSQL (Amazon RDS) |
| Monitoramento | Prometheus + Grafana |
| CI/CD | GitHub Actions |
| Nuvem | AWS (EC2 + RDS) |

## Estrutura do repositório

```
api/            Código-fonte da API (Go)
frontend/       Interface web
infra/terraform Provisionamento da infraestrutura AWS
infra/ansible   Configuração dos servidores
k8s/            Manifests/Helm do que roda no cluster
.github/        Pipelines de CI/CD
docs/           Documentação e decisões de arquitetura
scripts/        Scripts auxiliares
```

## Fluxo de branches (GitFlow)

- `main` — produção, recebe apenas merges de `release/x.y.z` validadas
- `develop` — homologação, recebe merges de `feature/bry-XXX` testadas
- `feature/bry-XXX-descricao` — desenvolvimento de cada etapa
- `release/x.y.z` — candidato de subida oficial para produção

## Documentação

Decisões técnicas e seus motivos estão registradas em `docs/adr/`. O passo a passo
completo de deploy (do `terraform apply` ao HTTPS funcionando) está em
`docs/RUNBOOK.md`. O vídeo tutorial demonstrando a criação do ambiente será linkado
aqui ao final do projeto.

## Status

🚧 Em desenvolvimento.
