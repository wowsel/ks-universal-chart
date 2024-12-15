# ks-universal Helm Chart

## Overview
`ks-universal` is a versatile Helm chart designed for deploying applications in Kubernetes. This chart provides a unified interface for managing various Kubernetes resources and supports most common deployment scenarios.

## Features
- Deployments management with multi-container support
- Automatic and manual Service creation
- Configuration management via ConfigMaps and Secrets
- Ingress traffic management
- Automatic scaling with HPA (Horizontal Pod Autoscaler)
- Availability management with PDB (Pod Disruption Budget)
- Permissions management via ServiceAccounts
- Jobs and migrations execution
- Monitoring setup with ServiceMonitor

## Prerequisites
- Kubernetes 1.19+
- Helm 3.0+
- Prometheus Operator (required for ServiceMonitor functionality)

## Quick Start

1. Add the repository and update:
```bash
helm repo add ks-universal https://your-repo-url.com
helm repo update
```

2. Install the chart:
```bash
helm install my-release ks-universal/ks-universal
```

## Values File Structure

The chart configuration is divided into the following main sections:

```yaml
deploymentsGeneral:  # Common settings for all deployments
  securityContext: {}
  nodeSelector: {}
  tolerations: []
  affinity: {}
  probes: {}
  lifecycle: {}
  autoCreateServiceMonitor: false
  autoCreateSoftAntiAffinity: false

deployments: {}      # Individual deployments configuration

configs: {}         # ConfigMaps and Secrets configuration

services: {}        # Explicit Services configuration

ingresses: {}       # Ingress resources configuration

jobs: {}            # Jobs configuration

generic: {}         # Chart-wide settings
```

## Default Configuration

By default, the chart creates no resources. All resources must be explicitly defined in the values.yaml file.

## Chart Upgrade

To upgrade an installed release:

```bash
helm upgrade my-release ks-universal/ks-universal
```

## Uninstalling

To delete an installed release:

```bash
helm uninstall my-release
```

## Documentation Structure

Detailed documentation for each resource type is available in separate files:
- [Deployments](./deployments.md)
- [Services](./services.md)
- [Configs](./configs.md)
- [Ingress](./ingress.md)
- [HPA](./hpa.md)
- [PDB](./pdb.md)
- [ServiceAccount](./serviceaccount.md)
- [Jobs](./jobs.md)
- [ServiceMonitor](./servicemonitor.md)

## Contributing
Contributions are welcome! Please read our [Contributing Guide](./CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License
Apache License 2.0
