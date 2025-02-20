# 🚀 KS Universal Helm Chart

> Universal Helm chart for deploying any type of application to Kubernetes with batteries included

[![Helm Version](https://img.shields.io/badge/helm-v3-blue)](https://helm.sh)
[![Kubernetes Version](https://img.shields.io/badge/kubernetes-%3E%3D%201.19-blue)](https://kubernetes.io)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue?style=flat-square)](LICENSE)

## ✨ Features

- 📦 **Resource Types**: Deployments, CronJobs, Jobs, Services, Ingresses, ConfigMaps/Secrets, PVCs
- 🤖 **Auto-creation**: Automatic creation of associated resources
- 📊 **Monitoring**: Native Prometheus support via ServiceMonitors
- 🔒 **Security**: SSL certificate management via cert-manager
- 🔄 **CI/CD**: Native Werf support
- 🛠️ **Multi-container**: Support for sidecar patterns
- ⚙️ **Configuration**: Flexible environment and secret management
- 🎯 **Validation**: Built-in configuration validation

## 🚀 Quick Start

1. Add the Helm repository:
```bash
helm repo add ks-universal https://wowsel.github.io/ks-universal-chart
helm repo update
```

2. Create a basic values.yaml:
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

3. Install the chart:
```bash
helm install my-release ks-universal/ks-universal -f values.yaml
```

## 🌟 Key Features Explained

### 🔄 Auto-creation Features

The chart can automatically create associated resources based on your configuration:

| Feature | Description | Activation |
|---------|-------------|------------|
| Service | Creates Service based on container ports | `autoCreateService: true` |
| Ingress | Creates Ingress with optional SSL | `autoCreateIngress: true` |
| Certificate | Manages SSL certificates via cert-manager | `autoCreateCertificate: true` |
| ServiceMonitor | Creates Prometheus ServiceMonitor | `autoCreateServiceMonitor: true` |
| PDB | Creates PodDisruptionBudget | `autoCreatePdb: true` |
| ServiceAccount | Creates dedicated ServiceAccount | `autoCreateServiceAccount: true` |

### 🔐 Secret Management

Advanced secret management with secret references: 

#### Please look at the [werf website](https://werf.io/docs/latest/usage/deploy/values.html#secret-parameters-werf-only) for a safe way to store secrets in the git. And our [integration guide](docs/werf-integration.md)

```yaml
secretRefs:
  shared-secrets:
    - name: API_KEY
      secretKeyRef:
        name: app-secrets
        key: api-key

deployments:
  my-app:
    containers:
      main:
        secretRefs:
          - shared-secrets  # Reference shared secrets
```

### 📊 Monitoring Integration

Native Prometheus monitoring support:

```yaml
deployments:
  my-app:
    autoCreateServiceMonitor: true
    containers:
      main:
        ports:
          http-metrics:
            containerPort: 9090
```

### 🔄 Database Migrations

Built-in support for database migrations:

```yaml
deployments:
  my-app:
    migrations:
      enabled: true
      args: ["migrate", "up"]
```

## 📚 Documentation

Detailed documentation is available in the [docs](docs) directory:

- [Getting Started](docs/getting-started.md)
- [Auto-creation Features](docs/auto-creation.md)
- [Monitoring](docs/monitoring.md)
- [Database Migrations](docs/database-migrations.md)
- [Advanced Features](docs/advanced-features.md)
- [FAQ](docs/faq.md)

## 📋 Requirements

- Kubernetes 1.19+
- Helm 3.0+
- cert-manager (optional, for SSL certificates)
- Prometheus Operator (optional, for monitoring)

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md).

## 📄 License

This project is licensed under the terms of the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
Maintained by [wowsel](https://github.com/wowsel).
## 🙏 Acknowledgments

Special thanks to the Kubernetes and Helm communities for inspiration and best practices.