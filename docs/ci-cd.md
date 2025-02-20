# CI/CD and Values Management

This guide explains how to effectively use the ks-universal chart in CI/CD pipelines and manage values across different environments.

## Table of Contents
- [GitHub Actions Integration](#github-actions-integration)
- [Values Management](#values-management)
- [Examples](#examples)
- [Best Practices](#best-practices)

## GitHub Actions Integration

### Basic Deployment Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy with Helm

on:
  push:
    branches: [ main ]
    paths-ignore:
      - 'docs/**'
      - '**.md'

env:
  ENVIRONMENT: production

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Helm
        uses: azure/setup-helm@v3
        
      - name: Add ks-universal repo
        run: |
          helm repo add ks-universal https://wowsel.github.io/ks-universal-chart
          helm repo update
          
      - name: Deploy
        run: |
          helm upgrade --install my-release ks-universal/ks-universal \
            -f values.yaml \
            -f values.${{ env.ENVIRONMENT }}.yaml \
            --namespace my-namespace \
            --create-namespace \
            --atomic \
            --timeout 5m
```

### Advanced Multi-environment Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy with Helm

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches: [ develop ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        include:
          - branch: main
            environment: production
            values_file: values.prod.yaml
          - branch: develop
            environment: staging
            values_file: values.staging.yaml
    
    environment:
      name: ${{ matrix.environment }}
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Helm
        uses: azure/setup-helm@v3
      
      - name: Add ks-universal repo
        run: |
          helm repo add ks-universal https://wowsel.github.io/ks-universal-chart
          helm repo update
      
      - name: Validate Helm Chart
        run: |
          helm template my-release ks-universal/ks-universal \
            -f values.yaml \
            -f ${{ matrix.values_file }} \
            --namespace ${{ matrix.environment }}
      
      - name: Deploy
        if: github.event_name == 'push'
        run: |
          helm upgrade --install my-release ks-universal/ks-universal \
            -f values.yaml \
            -f ${{ matrix.values_file }} \
            --namespace ${{ matrix.environment }} \
            --create-namespace \
            --atomic \
            --timeout 5m \
            --set global.environment=${{ matrix.environment }}
```

## Values Management

### Values Structure

```plaintext
/
├── values.yaml           # Base configuration
├── values.dev.yaml       # Development overrides
├── values.staging.yaml   # Staging overrides
├── values.prod.yaml      # Production overrides
└── values.secret.yaml    # Secret values (gitignored)
```

### Base Configuration (values.yaml)

```yaml
# values.yaml
deploymentsGeneral:
  securityContext:
    runAsNonRoot: true
  probes:
    livenessProbe:
      httpGet:
        path: /health
        port: http

deployments:
  backend:
    replicas: 2
    containers:
      main:
        image: my-app
        imageTag: v1.0.0
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

### Environment Overrides

```yaml
# values.dev.yaml
generic:
  ingressesGeneral:
    domain: dev.example.com

deployments:
  backend:
    replicas: 1  # Reduce replicas for dev
    containers:
      main:
        resources:
          requests:
            cpu: 50m
            memory: 64Mi

# values.prod.yaml
generic:
  ingressesGeneral:
    domain: example.com

deployments:
  backend:
    replicas: 3  # More replicas for production
    hpa:
      minReplicas: 3
      maxReplicas: 10
    containers:
      main:
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
```

## Examples

### Development Setup

```bash
# Local development
helm upgrade --install my-app ks-universal/ks-universal \
  -f values.yaml \
  -f values.dev.yaml \
  --namespace development

# With additional overrides
helm upgrade --install my-app ks-universal/ks-universal \
  -f values.yaml \
  -f values.dev.yaml \
  --set deployments.backend.replicas=1
```

### CI/CD Pipeline Example

```yaml
# .github/workflows/deploy.yml
name: Deploy Application

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ develop ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set environment
        id: env
        run: |
          if [[ ${{ github.ref }} == 'refs/heads/main' ]]; then
            echo "env_name=prod" >> $GITHUB_OUTPUT
          else
            echo "env_name=staging" >> $GITHUB_OUTPUT
          fi
      
      - name: Install Helm
        uses: azure/setup-helm@v3
      
      - name: Validate Helm templates
        run: |
          helm template my-app ks-universal/ks-universal \
            -f values.yaml \
            -f values.${{ steps.env.outputs.env_name }}.yaml \
            --namespace ${{ steps.env.outputs.env_name }}

  deploy:
    needs: validate
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set environment
        id: env
        run: |
          if [[ ${{ github.ref }} == 'refs/heads/main' ]]; then
            echo "env_name=prod" >> $GITHUB_OUTPUT
          else
            echo "env_name=staging" >> $GITHUB_OUTPUT
          fi
      
      - name: Install Helm
        uses: azure/setup-helm@v3
      
      - name: Deploy
        run: |
          helm upgrade --install my-app ks-universal/ks-universal \
            -f values.yaml \
            -f values.${{ steps.env.outputs.env_name }}.yaml \
            --namespace ${{ steps.env.outputs.env_name }} \
            --create-namespace \
            --atomic \
            --timeout 5m
```

## Best Practices

### 1. Values Organization

- Keep common configuration in `values.yaml`
- Use environment-specific files for overrides
- Store sensitive data separately
- Use clear naming conventions

### 2. Environment Management

- Use separate namespaces for environments
- Configure resource limits appropriately
- Adjust replica counts per environment
- Set appropriate domain names

### 3. CI/CD Pipeline

- Validate templates before deployment
- Use atomic deployments
- Set appropriate timeouts
- Include rollback strategies
- Add proper health checks

### 4. Security

- Keep secrets in a separate file
- Use environment variables for sensitive data
- Implement proper RBAC
- Configure network policies per environment

## Tips for Values Management

1. **Base Values Structure**
   ```yaml
   # values.yaml
   deploymentsGeneral:  # Common settings
   generic:             # Generic configurations
   deployments:         # Application definitions
   configs:            # Shared configurations
   ```

2. **Environment Overrides**
   ```yaml
   # values.prod.yaml
   generic:
     ingressesGeneral:
       domain: prod.example.com
   deployments:
     app:
       replicas: 3     # Production-specific
   ```

3. **Local Development**
   ```yaml
   # values.dev.yaml
   generic:
     ingressesGeneral:
       domain: dev.local
   deployments:
     app:
       replicas: 1     # Development-specific
   ```

## Common Patterns

### Feature Branch Testing

```yaml
# .github/workflows/feature.yml
name: Test Feature Branch

on:
  pull_request:
    branches: [ develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Helm
        uses: azure/setup-helm@v3
      
      - name: Deploy to feature namespace
        run: |
          NAMESPACE="feature-${GITHUB_HEAD_REF}"
          helm upgrade --install my-app ks-universal/ks-universal \
            -f values.yaml \
            -f values.dev.yaml \
            --set global.environment=feature \
            --namespace $NAMESPACE \
            --create-namespace
```

### Production Deployment

```yaml
# .github/workflows/production.yml
name: Production Deploy

on:
  release:
    types: [published]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Helm
        uses: azure/setup-helm@v3
      
      - name: Deploy to production
        run: |
          helm upgrade --install my-app ks-universal/ks-universal \
            -f values.yaml \
            -f values.prod.yaml \
            --set global.environment=production \
            --namespace production \
            --atomic \
            --timeout 10m
```