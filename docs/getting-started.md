# Getting Started with ks-universal

This guide will help you understand the basic concepts of the ks-universal chart and get your first application deployed.

## Table of Contents
- [Basic Concepts](#basic-concepts)
- [Installation](#installation)
- [First Deployment](#first-deployment)
- [Configuration Structure](#configuration-structure)
- [Next Steps](#next-steps)

## Basic Concepts

The ks-universal chart is built around several key concepts:

1. **Resource Types**
   - Deployments as the main application unit
   - Supporting resources (Services, Ingresses, etc.)
   - Configuration resources (ConfigMaps, Secrets)

2. **Auto-creation**
   - Automatic creation of dependent resources
   - Smart defaults based on container configuration

3. **Inheritance**
   - Global settings (`deploymentsGeneral`)
   - Generic settings (`generic`)
   - Resource-specific settings

## Installation

1. Add the Helm repository:
```bash
helm repo add ks-universal https://wowsel.github.io/ks-universal-chart
helm repo update
```

2. Install the chart:
```bash
helm install my-release ks-universal/ks-universal -f values.yaml
```

## First Deployment

Let's create a simple web application deployment:

```yaml
# values.yaml
deployments:
  web-app:
    # Enable automatic resource creation
    autoCreateService: true
    autoCreateIngress: true
    
    # Container configuration
    containers:
      main:
        image: nginx
        imageTag: 1.21
        ports:
          http:
            containerPort: 80
        
        # Basic resource limits
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
    
    # Ingress configuration
    ingress:
      hosts:
        - host: myapp.example.com
          paths:
            - path: /
              pathType: Prefix
```

Deploy with:
```bash
helm upgrade --install my-app ks-universal/ks-universal -f values.yaml
```

This will create:
- A Deployment running nginx
- A Service exposing port 80
- An Ingress routing traffic to myapp.example.com

## Configuration Structure

The chart uses a hierarchical configuration structure:

```yaml
# Global settings for all deployments
deploymentsGeneral:
  securityContext:
    runAsNonRoot: true
  probes:
    livenessProbe:
      httpGet:
        path: /health
        port: http

# Generic settings across resources
generic:
  ingressesGeneral:
    domain: example.com
  serviceMonitorGeneral:
    interval: 30s

# Specific deployments
deployments:
  app-name:
    # Inherits and can override global settings
    containers:
      main:
        image: my-app
        imageTag: v1.0.0
```

### Key Components

1. **Deployment Configuration**
   - Container settings
   - Resource requirements
   - Volume mounts
   - Environment variables

2. **Auto-creation Features**
   ```yaml
   deployments:
     my-app:
       autoCreateService: true
       autoCreateIngress: true
       autoCreateServiceMonitor: true
       autoCreatePdb: true
       autoCreateCertificate: true
   ```

3. **Container Configuration**
   ```yaml
   containers:
     main:
       image: my-app
       imageTag: v1.0.0
       ports:
         http:
           containerPort: 8080
       env:
         - name: ENV_VAR
           value: "value"
   ```

## Next Steps

After getting familiar with basic deployment, you might want to explore:

1. [Auto-creation Features](auto-creation.md) - Learn about automatic resource creation
2. [Monitoring](monitoring.md) - Set up Prometheus monitoring
3. [Database Migrations](database-migrations.md) - Handle database operations
4. [Advanced Features](advanced-features.md) - Explore advanced capabilities

## Common Patterns

### Web Application
```yaml
deployments:
  web-app:
    autoCreateService: true
    autoCreateIngress: true
    containers:
      main:
        image: web-app
        imageTag: v1.0.0
        ports:
          http:
            containerPort: 8080
```

### API Service
```yaml
deployments:
  api:
    autoCreateService: true
    autoCreateIngress: true
    autoCreateServiceMonitor: true
    containers:
      main:
        image: api-service
        imageTag: v1.0.0
        ports:
          http:
            containerPort: 8080
          metrics:
            containerPort: 9090
```

### Worker Service
```yaml
deployments:
  worker:
    # No ingress or service needed
    replicas: 2
    containers:
      main:
        image: worker
        imageTag: v1.0.0
        # No ports needed
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
```

## Tips and Best Practices

1. **Start Simple**
   - Begin with basic deployment configuration
   - Add features incrementally
   - Use auto-creation for common resources

2. **Resource Management**
   - Always specify resource requests and limits
   - Use appropriate replica counts
   - Consider using HPA for scaling

3. **Configuration**
   - Use `deploymentsGeneral` for shared settings
   - Keep environment-specific values separate
   - Use secrets for sensitive data

4. **Health Checks**
   - Configure appropriate probes
   - Set reasonable timeout values
   - Use startup probes for slow-starting applications