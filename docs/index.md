# KS Universal Chart Docs — Start Here

Welcome to the KS Universal Helm Chart documentation. This chart helps you deploy apps to Kubernetes quickly with batteries included.

- Deployments, Services, Ingress, HTTPRoutes (Gateway API), PVC, Jobs, CronJobs
- Auto-creation: Service, Ingress, HTTPRoute (Gateway API), Certificate, ServiceMonitor, PDB, ServiceAccount
- Monitoring (Prometheus), DexAuthenticator (Deckhouse only)

## 1-minute Quick Start

```bash
helm repo add ks-universal https://wowsel.github.io/ks-universal-chart
helm repo update

# Create a minimal values.yaml
cat > values.yaml <<'YAML'
deployments:
  web:
    autoCreateService: true
    autoCreateIngress: true
    containers:
      main:
        image: nginx
        imageTag: "1.25"
        ports:
          http:
            containerPort: 80
YAML

helm install my-web ks-universal/ks-universal -f values.yaml
```

## I want to…

- Deploy a simple web service → recipes/web-service.md
- Deploy an API with Prometheus metrics → recipes/api-with-metrics.md
- Run a CronJob → recipes/cronjob.md
- Run a one-off Job → recipes/job.md
- Add database migrations to my app → recipes/db-migrations.md
- Expose app via Ingress with TLS (cert-manager) → recipes/ingress-tls.md
- Expose app via Gateway API (HTTPRoute) → recipes/httproute.md
- Protect routes with DexAuthenticator (Deckhouse) → recipes/dexauthenticator.md

## Where to go next

- Getting started: getting-started.md
- Full values example: ../charts/ks-universal/values-example.yaml
- Troubleshooting: troubleshooting.md
- Auto-creation features: auto-creation.md
- Monitoring: monitoring.md
- Database migrations: database-migrations.md
- FAQ: faq.md
