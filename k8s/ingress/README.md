# Ingress — Nginx Ingress Controller

Cobre tanto o requisito de proxy reverso quanto o item de "Nginx como Ingress" do desafio.

## Instalação do controller (Helm)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  -f values-ingress-nginx.yaml
```

## Regra de roteamento da aplicação

`ingress.yaml` — troque `assinatura.SEUDOMINIO.com.br` pelo domínio real antes de aplicar
(precisa apontar via DNS para o IP público de um dos nodes, já que o Service do
controller é `LoadBalancer` servido pelo ServiceLB do K3s). Aplique **depois** que o
`cert-manager` (ver `../cert-manager/`) já estiver instalado, pois o annotation
`cert-manager.io/cluster-issuer` depende dele para emitir o certificado TLS.

```bash
kubectl apply -f ingress.yaml
```
