#!/usr/bin/env bash
# Smoke test pos-deploy: confere que o dominio publico esta respondendo em HTTPS,
# com certificado valido, e que a API funciona de ponta a ponta atraves do Ingress.
# Uso: ./scripts/smoke-test.sh assinatura.seudominio.com.br
set -euo pipefail

DOMAIN="${1:?Uso: $0 <dominio> (ex: assinatura.seudominio.com.br)}"
BASE_URL="https://${DOMAIN}"
FAIL=0

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "OK   - $desc"
  else
    echo "FAIL - $desc"
    FAIL=1
  fi
}

echo "== Smoke test: $BASE_URL =="

check "Frontend responde em HTTPS" \
  curl -sf --max-time 10 "$BASE_URL/"

check "Certificado TLS valido (nao e self-signed/expirado)" \
  curl -sf --max-time 10 -o /dev/null "$BASE_URL/"

sign_response=$(curl -sf --max-time 10 -X POST "$BASE_URL/api/sign" \
  -H "Content-Type: application/json" \
  -d '{"document":"smoke-test"}') || sign_response=""

if echo "$sign_response" | grep -q '"signature"'; then
  echo "OK   - POST /api/sign retorna assinatura"
else
  echo "FAIL - POST /api/sign nao retornou o campo 'signature'"
  FAIL=1
fi

check "GET /api/signatures responde" \
  curl -sf --max-time 10 "$BASE_URL/api/signatures?limit=1"

if [ -n "${KUBECONFIG:-}" ] && command -v kubectl >/dev/null 2>&1; then
  ready_api=$(kubectl -n bry-desafio get deployment api -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
  if [ "${ready_api:-0}" -ge 2 ]; then
    echo "OK   - Deployment api com $ready_api replicas prontas (HA confirmada)"
  else
    echo "FAIL - Deployment api com apenas ${ready_api:-0} replica(s) pronta(s), esperado >=2"
    FAIL=1
  fi
else
  echo "SKIP - KUBECONFIG nao setado, pulando checagem de replicas via kubectl"
fi

echo "=========================="
if [ "$FAIL" -eq 0 ]; then
  echo "Todos os checks passaram."
else
  echo "Um ou mais checks falharam - ver acima."
  exit 1
fi
