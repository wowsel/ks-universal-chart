# Universal Kubernetes Helm Chart

A flexible and feature-rich Helm chart for deploying various Kubernetes resources. Designed to support multiple deployment scenarios while maintaining best practices and providing extensive customization options.

## Features

- **Resource Types**: Deployments, CronJobs, Jobs, Services, Ingresses, ConfigMaps/Secrets, PVCs, HPAs, PDBs, ServiceMonitors, ServiceAccounts, Certificates
- **Auto-creation**: Automatic creation of associated resources (Services, Ingress, Certificates, ServiceMonitors, PDBs)
- **Monitoring**: Native Prometheus support
- **Security**: SSL certificate management via cert-manager
- **CI/CD**: Native support for Werf and GitHub Actions
- **Multi-container**: Support for multi-container pods
- **Configuration**: Flexible environment variables and config mounting

## Quick Start

Add the Helm repository:

```bash
helm repo add ks-universal https://wowsel.github.io/ks-universal-chart
helm repo update
```

Basic deployment example:

```yaml
deployments:
  my-app:
    replicas: 2
    autoCreateService: true
    autoCreateIngress: true
    containers:
      main:
        image: my-app
        imageTag: v1.0.0
        ports:
          http:
            containerPort: 8080
```

## Documentation

### Core Concepts
- [Getting Started](docs/getting-started.md) - Basic concepts and first steps
- [Auto-creation Features](docs/auto-creation.md) - Automatic resource creation
- [Advanced Features](docs/advanced-features.md) - Advanced usage and patterns
- [CI/CD and Values Management](docs/ci-cd.md) - CI/CD integration and values handling

### CI/CD Integration

The chart supports seamless integration with various CI/CD platforms. Here's a basic GitHub Actions example:

```yaml
name: Deploy with Helm

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Helm
        uses: azure/setup-helm@v3
        
      - name: Deploy
        run: |
          helm upgrade --install my-release ks-universal/ks-universal \
            -f values.yaml \
            -f values.prod.yaml \
            --namespace my-namespace
```

For detailed CI/CD configuration and values management strategies, see our [CI/CD and Values Management Guide](docs/ci-cd.md).

### Values Management

The chart supports flexible values management across different environments:

```plaintext
/
├── values.yaml           # Base configuration
├── values.dev.yaml       # Development overrides
├── values.staging.yaml   # Staging overrides
└── values.prod.yaml      # Production overrides
```

Example usage:
```bash
# Development
helm upgrade --install my-app ks-universal/ks-universal -f values.yaml -f values.dev.yaml

# Production
helm upgrade --install my-app ks-universal/ks-universal -f values.yaml -f values.prod.yaml
```

See the [CI/CD and Values Management Guide](docs/ci-cd.md) for detailed examples and best practices.

### Features
- [Monitoring](docs/monitoring.md) - Prometheus integration and monitoring
- [Database Migrations](docs/database-migrations.md) - Database operations and migrations
- [Werf Integration](docs/werf-integration.md) - Using with Werf

### Examples
- [Simple Web Application](examples/simple-web-app)
- [Microservices Architecture](examples/microservices)
- [Database Application](examples/database-app)
- [Monitoring Setup](examples/monitoring)

## Contributing

We welcome contributions! Please check our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Requirements

- Kubernetes 1.19+
- Helm 3.0+
- cert-manager (optional, for SSL certificates)
- Prometheus Operator (optional, for monitoring)

## Support

For questions and support:
- [Open an issue](https://github.com/wowsel/ks-universal-chart/issues)
- Check our [FAQ](docs/faq.md)