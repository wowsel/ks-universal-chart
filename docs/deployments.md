# Deployments Configuration

## Overview
The deployments configuration is the core component of the ks-universal chart. It supports creating Kubernetes Deployments with multiple containers, advanced scheduling options, and various pod configurations.

## Structure

### General Deployment Settings (deploymentsGeneral)
These settings apply to all deployments unless overridden in specific deployment configurations.

```yaml
deploymentsGeneral:
  securityContext: {}      # Pod security context
  nodeSelector: {}         # Node selection constraints
  tolerations: []         # Pod tolerations
  affinity: {}            # Pod affinity rules
  probes: {}              # Default probe configurations
  lifecycle: {}           # Default lifecycle hooks
  autoCreateServiceMonitor: false  # Enable ServiceMonitor creation
  autoCreateSoftAntiAffinity: false  # Enable soft anti-affinity
```

### Individual Deployment Configuration
Each deployment is configured under the `deployments` section:

```yaml
deployments:
  deployment-name:
    replicas: 1           # Number of pod replicas
    containers:           # Container configurations
      container-name:
        image: nginx      # Container image
        imageTag: latest  # Image tag
        ports:           # Container ports
          http:
            containerPort: 80
            protocol: TCP
        resources: {}     # Resource requests and limits
        probes: {}       # Container probes
        env: []          # Environment variables
        envFrom: []      # Environment from ConfigMaps/Secrets
        lifecycle: {}    # Container lifecycle hooks
    
    serviceAccount: {}    # ServiceAccount configuration
    autoCreateService: true  # Create Service automatically
    serviceType: ClusterIP   # Service type
    hpa: {}              # HPA configuration
    pdb: {}             # PDB configuration
    migrations: {}       # Migration job configuration
```

## Features

### Multi-Container Support
Each deployment can contain multiple containers with individual configurations:

```yaml
deployments:
  web-app:
    containers:
      nginx:
        image: nginx
        imageTag: 1.19
        ports:
          http:
            containerPort: 80
      php-fpm:
        image: php
        imageTag: 7.4-fpm
```

### Environment Variables
Support for both direct values and references to ConfigMaps/Secrets:

```yaml
containers:
  app:
    env:
      - name: DATABASE_URL
        value: "postgresql://db:5432"
      - name: API_KEY
        valueFrom:
          secretKeyRef:
            name: app-secrets
            key: api-key
    envFrom:
      - type: configMap
        configName: app-config
```

### Probes Configuration
Comprehensive health check configuration:

```yaml
containers:
  app:
    probes:
      livenessProbe:
        httpGet:
          path: /health
          port: http
        initialDelaySeconds: 30
      readinessProbe:
        httpGet:
          path: /ready
          port: http
```

### Advanced Scheduling
Support for affinity, anti-affinity, and node selection:

```yaml
deployments:
  web-app:
    nodeSelector:
      node-role: web
    tolerations:
      - key: "key"
        operator: "Equal"
        value: "value"
        effect: "NoSchedule"
    autoCreateSoftAntiAffinity: true
```

## Examples

### Basic Web Application
```yaml
deployments:
  web-app:
    replicas: 3
    containers:
      nginx:
        image: nginx
        imageTag: 1.19
        ports:
          http:
            containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
    autoCreateService: true
    serviceType: ClusterIP
```

### Stateful Application with Migrations
```yaml
deployments:
  backend:
    containers:
      app:
        image: backend-app
        imageTag: v1.0.0
        ports:
          http:
            containerPort: 8080
    migrations:
      enabled: true
      args:
        - migrate
        - --database
        - postgresql://db:5432
```

### Scaled Application with HPA
```yaml
deployments:
  api:
    containers:
      api:
        image: api-service
        imageTag: v2.0.0
    hpa:
      minReplicas: 2
      maxReplicas: 10
      metrics:
        - type: Resource
          resource:
            name: cpu
            target:
              type: Utilization
              averageUtilization: 80
```

## Notes
- All container images and tags must be explicitly specified
- At least one container must be defined for each deployment
- Port names must be unique within a container
- Environment variables must have either `value` or `valueFrom` specified

## See Also
- [Services Configuration](./services.md)
- [HPA Configuration](./hpa.md)
- [PDB Configuration](./pdb.md)
