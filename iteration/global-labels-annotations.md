# Global Labels and Annotations Support

## Version: 0.2.22

## Overview

Added support for global labels and annotations that are automatically applied to all resources in the chart. This feature allows users to define common metadata once in `generic.labels` and `generic.annotations`, which then propagates to all Kubernetes resources.

## Configuration

### Location in values.yaml

```yaml
generic:
  labels:
    team: platform
    environment: production
    cost-center: "12345"
  annotations:
    company.com/owner: "platform-team"
    company.com/slack: "#platform-alerts"
```

### Merge Priority (lowest to highest)

```
generic.labels/annotations (global)
  → deploymentsGeneral.labels/annotations (for deployments/jobs/cronjobs)
    → resource.labels/annotations (specific resource)
```

Resource-specific labels/annotations always override global and deploymentsGeneral labels/annotations.

## Affected Resources

Global labels and annotations are applied to:

- **Deployments** (metadata + pod template)
- **Jobs** (metadata + pod template)
- **CronJobs** (metadata + jobTemplate metadata + pod template)
- **Services**
- **Ingresses** (via explicit ingresses and autoCreateIngress)
- **ConfigMaps/Secrets** (configs)
- **Certificates**
- **ServiceAccounts**
- **ServiceMonitors**
- **HorizontalPodAutoscalers**
- **PodDisruptionBudgets**
- **PersistentVolumeClaims**
- **DexAuthenticators**

## Usage Example

### Base values (values-base.yaml)

```yaml
generic:
  labels:
    environment: production
    team: platform
    cost-center: "12345"
  annotations:
    company.com/owner: "platform-team"
    company.com/slack: "#platform-alerts"
```

### App values (values-app.yaml)

```yaml
deployments:
  my-app:
    labels:
      app.kubernetes.io/tier: frontend  # adds to global
    annotations:
      prometheus.io/scrape: "true"      # adds to global
    containers:
      main:
        image: myapp
        imageTag: v1.0.0
```

### Resulting Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    helm.sh/chart: ks-universal-0.2.22
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: my-app
    environment: production        # from generic
    team: platform                 # from generic
    cost-center: "12345"           # from generic
    app.kubernetes.io/tier: frontend  # from deployment
  annotations:
    company.com/owner: "platform-team"   # from generic
    company.com/slack: "#platform-alerts" # from generic
    prometheus.io/scrape: "true"          # from deployment
spec:
  template:
    metadata:
      labels:
        # Same labels applied to pods
        environment: production
        team: platform
        cost-center: "12345"
        app.kubernetes.io/tier: frontend
      annotations:
        # Same annotations applied to pods
        company.com/owner: "platform-team"
        company.com/slack: "#platform-alerts"
        prometheus.io/scrape: "true"
```

## Implementation Details

### New Helper Functions

Two new helper functions were added to `_helpers.tpl`:

- `ks-universal.mergeLabels` - Merges resource-specific labels with global labels
- `ks-universal.mergeAnnotations` - Merges resource-specific annotations with global annotations

### deploymentsGeneral Support

The `deploymentsGeneral` section now supports `labels` and `annotations`:

```yaml
deploymentsGeneral:
  labels:
    tier: backend
  annotations:
    app-type: service
```

These are applied to all deployments, jobs, and cronjobs with priority between generic and resource-specific values.

## Files Modified

1. `charts/ks-universal/values.yaml`
2. `charts/ks-universal/templates/_helpers.tpl`
3. `charts/ks-universal/templates/deployment.yaml`
4. `charts/ks-universal/templates/job.yaml`
5. `charts/ks-universal/templates/cronjob.yaml`
6. `charts/ks-universal/templates/service.yaml`
7. `charts/ks-universal/templates/ingress.yaml`
8. `charts/ks-universal/templates/configs.yaml`
9. `charts/ks-universal/templates/certificate.yaml`
10. `charts/ks-universal/templates/serviceaccount.yaml`
11. `charts/ks-universal/templates/servicemonitor.yaml`
12. `charts/ks-universal/templates/hpa.yaml`
13. `charts/ks-universal/templates/pdb.yaml`
14. `charts/ks-universal/templates/pvc.yaml`
15. `charts/ks-universal/templates/dexauthenticator.yaml`
16. `charts/ks-universal/Chart.yaml`

## New Test File

`charts/ks-universal/tests/global_labels_test.yaml` - Tests for global labels and annotations functionality

## Verification

```bash
# Run tests
helm unittest charts/ks-universal

# Template render check
helm template test ./charts/ks-universal \
  --set generic.labels.team=moments \
  --set generic.annotations.owner=dev-team \
  --set deployments.myapp.containers.main.image=nginx \
  --set deployments.myapp.containers.main.imageTag=latest
```
