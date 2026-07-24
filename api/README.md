# API — Simulação de Assinatura Digital

Serviço em Go responsável por simular a assinatura digital de documentos.

- `cmd/api/` — ponto de entrada da aplicação (main.go)
- `internal/signer/` — gera o par de chaves RSA e assina o hash SHA-256 do documento
- `internal/store/` — persiste o histórico de assinaturas no PostgreSQL
- `internal/handler/` — endpoints HTTP

## Endpoints

| Método | Rota | Descrição |
|---|---|---|
| GET | `/healthz` | Liveness probe |
| GET | `/readyz` | Readiness probe (verifica conexão com o banco) |
| POST | `/api/sign` | Recebe `{"document": "..."}`, retorna hash + assinatura |
| GET | `/api/signatures?limit=20` | Lista o histórico de assinaturas |

## Rodando localmente

Na raiz do repositório:

```
docker-compose up -d --build
curl http://localhost:8080/healthz
curl -X POST http://localhost:8080/api/sign -H "Content-Type: application/json" -d "{\"document\":\"teste\"}"
docker-compose down -v
```

Variáveis de ambiente em `.env.example`.

Empacotado via `Dockerfile` (multi-stage, imagem final `distroless:nonroot`) para deploy no cluster Kubernetes.
