# API — Simulação de Assinatura Digital

Serviço em Go responsável por simular a assinatura digital de documentos.

- `cmd/` — ponto de entrada da aplicação (main.go)
- `internal/` — lógica de negócio, handlers HTTP e integração com o banco

Empacotado via `Dockerfile` para deploy no cluster Kubernetes.
