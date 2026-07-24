# Monitoring — Prometheus + Grafana

## Instalação (Helm)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f values-kube-prometheus-stack.yaml \
  --set grafana.adminPassword="<defina-uma-senha-aqui>"
```

`kubeEtcd`/`kubeControllerManager`/`kubeScheduler` ficam desabilitados porque o K3s
não expõe esses componentes da forma que o chart espera (control-plane embutido) —
habilitá-los só gera alvos de scrape sempre down.

## Acesso ao Grafana

Grafana **não** tem Ingress/exposição pública — é acessado sob demanda:

```bash
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
```
