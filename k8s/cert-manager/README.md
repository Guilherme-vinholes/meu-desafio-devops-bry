# cert-manager — HTTPS automático via Let's Encrypt

## Instalação (Helm)

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true
```

## ClusterIssuer

`cluster-issuer.yaml` — troque o e-mail antes de aplicar (Let's Encrypt manda avisos de
expiração/rate-limit para ele, não é usado para nada além disso):

```bash
kubectl apply -f cluster-issuer.yaml
```

Depois disso, o `Ingress` em `../ingress/ingress.yaml` (com a annotation
`cert-manager.io/cluster-issuer: letsencrypt-prod`) já recebe o certificado
automaticamente assim que for aplicado — sem passo manual adicional.

**Pré-requisito**: o domínio usado no Ingress precisa estar resolvendo (DNS) para o
IP público de um dos nodes antes de aplicar, senão o desafio HTTP-01 falha.
