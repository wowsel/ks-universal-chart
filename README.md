# 🚀 Universal Kubernetes Helm Chart
# Still in development! For testing use only! Do not use in production or anywhere else!
This Helm chart provides a flexible and feature-rich way to deploy various Kubernetes resources with extensive customization options.

## Table of Contents
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Typical Application Example](#typical-application-example)
- [Configuration Reference](#configuration-reference)
- [Auto-creation Features](#auto-creation-features)
- [Advanced Features](#advanced-features)

## 📑 Chart Structure

<details>
<summary>Full Chart Structure</summary>

```yaml
# Global deployment settings
deploymentsGeneral:
  securityContext: {}      # Pod security context
  nodeSelector: {}         # Node selection constraints
  tolerations: []         # Pod tolerations
  affinity: {}            # Pod affinity rules
  probes: {}              # Default probe configurations
  lifecycle: {}           # Default lifecycle hooks
  autoCreateServiceMonitor: false  # Enable ServiceMonitor creation
  autoCreateSoftAntiAffinity: false  # Enable soft anti-affinity

# Generic settings
generic:
  extraImagePullSecrets: []  # Global image pull secrets
  ingressesGeneral: {}       # Global ingress configurations
  serviceMonitorGeneral: {}  # Global ServiceMonitor settings

# Deployments
deployments:
  deployment-name:
    replicas: 1           # Number of pod replicas
    containers:           # Container configurations
      container-name:
        image: nginx      # Container image
        imageTag: latest  # Image tag
        ports:           # Container ports
          portName:
            containerPort: 80
            protocol: TCP
        resources: {}     # Resource requests and limits
        probes: {}       # Container probes
        env: []          # Environment variables
        envFrom: []      # Environment from ConfigMaps/Secrets
        volumeMounts: [] # Volume mounts
        lifecycle: {}    # Container lifecycle hooks
        command: []      # Container command
        args: []         # Command arguments
        securityContext: {} # Container security context
    
    # Deployment features
    autoCreateService: false        # Create Service automatically
    autoCreateIngress: false        # Create Ingress automatically
    autoCreateServiceMonitor: false # Create ServiceMonitor
    autoCreatePdb: false           # Create PDB
    autoCreateCertificate: false   # Create Certificate
    autoCreateServiceAccount: false # Create ServiceAccount
    autoCreateSoftAntiAffinity: false # Enable soft anti-affinity
    
    # Additional configurations
    serviceType: ClusterIP    # Service type when autoCreateService is true
    ingress: {}              # Ingress configuration
    certificate: {}          # Certificate configuration
    serviceMonitor: {}       # ServiceMonitor configuration
    pdbConfig: {}           # PDB configuration
    serviceAccount: {}       # ServiceAccount configuration
    
    # Scaling and availability
    hpa:                     # HPA configuration
      minReplicas: 1
      maxReplicas: 10
      metrics: []
    
    # Database migrations
    migrations:
      enabled: false
      args: []
      backoffLimit: 1
    
    # Resources
    volumes: []             # Pod volumes
    nodeSelector: {}        # Node selection
    tolerations: []        # Pod tolerations
    affinity: {}           # Pod affinity rules
    annotations: {}        # Deployment annotations
    podAnnotations: {}     # Pod annotations

# CronJobs
cronJobs:
  cronjob-name:
    schedule: "* * * * *"
    timezone: ""
    successfulJobsHistoryLimit: 3
    failedJobsHistoryLimit: 1
    concurrencyPolicy: Allow
    containers: {}     # Same structure as deployment containers
    volumes: []
    nodeSelector: {}
    tolerations: []
    affinity: {}

# One-time Jobs
jobs:
  job-name:
    activeDeadlineSeconds: null
    backoffLimit: 6
    containers: {}     # Same structure as deployment containers
    volumes: []
    nodeSelector: {}
    tolerations: []
    affinity: {}

# Configurations
configs:
  config-name:
    type: configMap    # or "secret"
    data: {}          # Key-value pairs

# Standalone Services
services:
  service-name:
    type: ClusterIP
    ports:
      - name: http
        port: 80
        targetPort: 80
        protocol: TCP

# PersistentVolumeClaims
persistentVolumeClaims:
  pvc-name:
    accessModes: []
    storageClassName: ""
    size: 1Gi

# Standalone Ingresses
ingresses:
  ingress-name:
    annotations: {}
    ingressClassName: ""
    tls: []
    hosts: []
```
</details>

- **Resource Types Support**: Deployments, CronJobs, Jobs, Services, Ingresses, ConfigMaps/Secrets, PVCs, HPAs, PDBs, ServiceMonitors, ServiceAccounts, Certificates
- **Auto-creation**: Automatic creation of associated resources (Services, Ingress, Certificates, ServiceMonitors, PDBs)
- **Validation**: Built-in validation system for configuration correctness
- **Monitoring**: Native support for Prometheus monitoring
- **Security**: SSL certificate management via cert-manager
- **Multi-container**: Support for multi-container pods
- **Configuration**: Flexible environment variables and config mounting

## 🔧 Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- cert-manager (for certificate management)
- Prometheus Operator (for monitoring)

## 🚀 Quick Start

<details>
<summary>Basic Deployment Example</summary>

```yaml
deployments:
  my-app:
    replicas: 2
    autoCreateService: true
    containers:
      main:
        image: my-app
        imageTag: v1.0.0
        ports:
          http:
            containerPort: 8080
```
</details>

## Typical Application Example

Let's look at a complete example of deploying a typical application with frontend, backend, and database migrations.

<details>
<summary>Complete Application Stack</summary>

```yaml
# Global configurations
deploymentsGeneral:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
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
      initialDelaySeconds: 5

# ConfigMaps and Secrets
configs:
  app-config:
    type: configMap
    data:
      config.yaml: |
        environment: production
        log_level: info
        redis:
          host: redis-master
          port: 6379
        features:
          metrics: true
          tracing: true
      nginx.conf: |
        worker_processes auto;
        events {
          worker_connections 1024;
        }
  app-secrets:
    type: secret
    data:
      DB_PASSWORD: "your-db-password"
      API_KEY: "your-api-key"
      REDIS_PASSWORD: "redis-password"
secretRefs:
  db-secrets:
    - name: DB_PASSWORD_SHARED
      secretKeyRef:
        name: database-creds
        key: password
    - name: DB_USER_SHARED
      secretKeyRef:
        name: database-creds
        key: username
# Redis service for caching
deployments:
  redis:
    replicas: 1
    autoCreateService: true
    autoCreatePdb: true
    pdbConfig:
      minAvailable: 1
    containers:
      main:
        image: redis
        imageTag: "6.2-alpine"
        ports:
          redis:
            containerPort: 6379
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        volumeMounts:
          - name: redis-data
            mountPath: /data
    volumes:
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-data

# Backend API service
  backend-api:
    replicas: 3
    autoCreateService: true
    autoCreateIngress: true
    autoCreateServiceMonitor: true
    autoCreateSoftAntiAffinity: true
    migrations:
      enabled: true
      args:
        - "migrate"
        - "up"
      backoffLimit: 3
    containers:
      main:
        image: backend-api
        imageTag: v1.0.0
        ports:
          http:
            containerPort: 8080
          metrics:
            containerPort: 9090
        env:
          - name: DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: app-secrets
                key: DB_PASSWORD
          - name: REDIS_HOST
            value: redis
          - name: REDIS_PASSWORD
            valueFrom:
              secretKeyRef:
                name: app-secrets
                key: REDIS_PASSWORD
        secretRefs:
          - db-secrets        
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        volumeMounts:
          - name: tmp-data
            mountPath: /tmp
    volumes:
      - name: tmp-data
        emptyDir: {}
    ingress:
      annotations:
        nginx.ingress.kubernetes.io/proxy-body-size: "10m"
      hosts:
        - host: api.example.com
          paths:
            - path: /
              pathType: Prefix
    hpa:
      minReplicas: 3
      maxReplicas: 10
      metrics:
        - type: Resource
          resource:
            name: cpu
            target:
              type: Utilization
              averageUtilization: 80
    serviceMonitor:
      endpoints:
        - port: metrics
          interval: 15s

  # Frontend application
  frontend:
    replicas: 2
    autoCreateService: true
    autoCreateIngress: true
    autoCreateCertificate: true
    autoCreateSoftAntiAffinity: true
    containers:
      main:
        image: frontend
        imageTag: v1.0.0
        ports:
          http:
            containerPort: 80
        env:
          - name: API_URL
            value: https://api.example.com
          - name: NODE_ENV
            value: production
        resources:
          requests:
            cpu: 50m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        volumeMounts:
          - name: nginx-config
            mountPath: /etc/nginx/nginx.conf
            subPath: nginx.conf
    volumes:
      - name: nginx-config
        configMap:
          name: app-config
    ingress:
      annotations:
        nginx.ingress.kubernetes.io/proxy-body-size: "10m"
      hosts:
        - host: app.example.com
          paths:
            - path: /
              pathType: Prefix
      ingressClassName: nginx
    certificate:
      clusterIssuer: letsencrypt-prod
```
</details>

## 📖 Configuration Reference

### Deployment Configuration

<details>
<summary>Basic Deployment Settings</summary>

```yaml
deployments:
  my-deployment:
    replicas: 2                    # Number of replicas
    autoCreateService: true        # Automatically create a service
    autoCreateIngress: true        # Automatically create an ingress
    autoCreateServiceMonitor: true # Create Prometheus ServiceMonitor
    containers:
      main:
        image: myapp              # Container image
        imageTag: v1.0.0          # Image tag
        ports:
          http:
            containerPort: 8080   # Container port
```
</details>

<details>
<summary>Advanced Deployment Settings</summary>

```yaml
deployments:
  my-deployment:
    # Migration configuration
    migrations:
      enabled: true
      args:
        - "migrate"
        - "up"
      backoffLimit: 3

    # HPA configuration
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

    # PDB configuration
    autoCreatePdb: true
    pdbConfig:
      minAvailable: 1

    # Container configuration
    containers:
      main:
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
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
            initialDelaySeconds: 5
```
</details>

### Configuration and Secrets

<details>
<summary>ConfigMaps and Secrets</summary>

```yaml
configs:
  app-config:
    type: configMap
    data:
      config.yaml: |
        key1: value1
        key2: value2

  app-secrets:
    type: secret
    data:
      API_KEY: "secret-key"
      DB_PASSWORD: "db-password"
```
</details>

### Environment Variables

<details>
<summary>Environment Variables Configuration</summary>

```yaml
containers:
  main:
    env:
      # Direct value
      - name: ENVIRONMENT
        value: "production"
      
      # From ConfigMap
      - name: CONFIG_KEY
        valueFrom:
          configMapKeyRef:
            name: app-config
            key: config_key
      
      # From Secret
      - name: API_KEY
        valueFrom:
          secretKeyRef:
            name: app-secrets
            key: API_KEY

    # Load all values from ConfigMap/Secret
    envFrom:
      - type: configMap
        configName: app-config
      - type: secret
        configName: app-secrets
```
</details>

### Secret References

<details>
<summary>Secret References Configuration</summary>

First, define your secret reference groups in the `secretRefs` section:

```yaml
secretRefs:
  shared-secrets:  # Group name for common secrets
    - name: S3_SECRET  # Environment variable name
      secretKeyRef:
        name: passwords  # Secret resource name
        key: s3-secret-key  # Key in the secret
    - name: OPENSEARCH_PASSWORD
      secretKeyRef:
        name: passwords
        key: opensearch-password
  
  db-secrets:  # Another group for database credentials
    - name: DB_PASSWORD
      secretKeyRef:
        name: database-creds
        key: password
    - name: DB_USER
      secretKeyRef:
        name: database-creds
        key: username
```

Then reference these groups in your container configuration:

```yaml
deployments:
  backend-api:
    containers:
      main:
        secretRefs:
          - shared-secrets  # Reference the secret group
          - db-secrets     # Can use multiple groups
```

This will automatically expand to individual environment variables in the deployment:

```yaml
containers:
  - name: main
    env:
      - name: S3_SECRET
        valueFrom:
          secretKeyRef:
            name: passwords
            key: s3-secret-key
      - name: OPENSEARCH_PASSWORD
        valueFrom:
          secretKeyRef:
            name: passwords
            key: opensearch-password
      - name: DB_PASSWORD
        valueFrom:
          secretKeyRef:
            name: database-creds
            key: password
      - name: DB_USER
        valueFrom:
          secretKeyRef:
            name: database-creds
            key: username
```

#### Benefits

- **DRY (Don't Repeat Yourself)**: Define secret references once and reuse them across multiple deployments
- **Maintainability**: Update secret references in one place
- **Grouping**: Organize secrets logically by their purpose or application component
- **Flexibility**: Mix and match secret groups as needed for each container

#### Usage Tips

1. Group secrets logically (e.g., database credentials, API keys, shared secrets)
2. Use descriptive group names that indicate the purpose of the secrets
3. You can combine `secretRefs` with regular `env` entries in your container configuration
4. Multiple containers can reference the same secret groups

#### Example with Multiple Features

```yaml
secretRefs:
  shared-secrets:
    - name: S3_SECRET
      secretKeyRef:
        name: passwords
        key: s3-secret-key
    - name: API_KEY
      secretKeyRef:
        name: passwords
        key: api-key

deployments:
  backend-api:
    containers:
      main:
        image: backend-api
        imageTag: v1.0.0
        ports:
          http:
            containerPort: 8080
        secretRefs:
          - shared-secrets
        env:
          - name: ADDITIONAL_VAR
            value: "custom-value"
          - name: CUSTOM_SECRET
            valueFrom:
              secretKeyRef:
                name: custom-secrets
                key: special-key
```

</details>

### Volume Mounts

<details>
<summary>Volume Configuration</summary>

```yaml
deployments:
  my-deployment:
    containers:
      main:
        volumeMounts:
          - name: config-volume
            mountPath: /config
            readOnly: true
          - name: data-volume
            mountPath: /data
    
    volumes:
      - name: config-volume
        configMap:
          name: app-config
      - name: data-volume
        persistentVolumeClaim:
          claimName: data-pvc
```
</details>

## Auto-creation Features

### Service Auto-creation

<details>
<summary>Service Configuration</summary>

```yaml
deployments:
  my-deployment:
    autoCreateService: true
    containers:
      main:
        ports:
          http:
            containerPort: 8080
          https:
            containerPort: 8443
```
</details>

### Ingress Auto-creation

<details>
<summary>Ingress Configuration</summary>

```yaml
deployments:
  my-deployment:
    autoCreateIngress: true
    ingress:
      hosts:
        - host: myapp.example.com
          paths:
            - path: /
              pathType: Prefix
      annotations:
        nginx.ingress.kubernetes.io/proxy-body-size: "50m"
```
</details>

### Certificate Auto-creation

<details>
<summary>Certificate Configuration</summary>

```yaml
deployments:
  my-deployment:
    autoCreateCertificate: true
    certificate:
      clusterIssuer: letsencrypt-prod
    ingress:
      hosts:
        - host: myapp.example.com
          paths:
            - path: /
              pathType: Prefix
```
</details>

## Scheduled Tasks

### CronJobs

<details>
<summary>CronJob Configuration</summary>

```yaml
cronJobs:
  backup-job:
    schedule: "0 0 * * *"  # Run daily at midnight
    timezone: "UTC"        # Timezone for the schedule
    successfulJobsHistoryLimit: 3
    failedJobsHistoryLimit: 1
    concurrencyPolicy: Forbid
    containers:
      main:
        image: backup-tool
        imageTag: v1.0.0
        env:
          - name: BACKUP_PATH
            value: "/backup"
          - name: AWS_ACCESS_KEY_ID
            valueFrom:
              secretKeyRef:
                name: backup-secrets
                key: aws-key
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
    volumes:
      - name: backup-volume
        persistentVolumeClaim:
          claimName: backup-pvc
```
</details>

### One-time Jobs

<details>
<summary>Job Configuration</summary>

```yaml
jobs:
  data-import:
    activeDeadlineSeconds: 3600
    backoffLimit: 3
    # Run job on specific nodes
    nodeSelector:
      job-type: batch
    containers:
      main:
        image: data-import
        imageTag: v1.0.0
        command: ["python", "/app/import.py"]
        args: ["--mode", "full"]
        env:
          - name: INPUT_FILE
            value: "/data/input.csv"
          - name: DB_CONNECTION
            valueFrom:
              secretKeyRef:
                name: db-secrets
                key: connection-string
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        volumeMounts:
          - name: import-data
            mountPath: /data
    volumes:
      - name: import-data
        persistentVolumeClaim:
          claimName: import-pvc
```
</details>

## 🛠️ Advanced Features

### Database Migrations

<details>
<summary>Database Migration Configuration</summary>

```yaml
deployments:
  my-app:
    migrations:
      enabled: true
      args:
        - "migrate"
        - "up"
      backoffLimit: 3
    containers:
      main:
        image: myapp
        imageTag: v1.0.0
        env:
          - name: DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: app-secrets
                key: DB_PASSWORD
```
</details>

### Prometheus Monitoring

<details>
<summary>Monitoring Configuration</summary>
The serviceMonitor section is optional, if not specified the following logic will be used:
- First, a port named "http-metrics" is searched among all containers
- If no such port is found, the first available port from the first container is taken

The default Prometheus interval and timeout will be used, /metrics as the path.
```yaml
deployments:
  my-app:
    autoCreateServiceMonitor: true
    containers:
      main:
        ports:
          http-metrics:
            containerPort: 9090
    serviceMonitor:
      endpoints:
        - port: http-metrics
          interval: 15s
```
OR if you only have one endpoint
```yaml
serviceMonitor:
  path: /metrics
  interval: 30s
  scrapeTimeout: 10s
```
</details>

### Horizontal Pod Autoscaling

<details>
<summary>HPA Configuration</summary>

```yaml
deployments:
  my-app:
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
</details>

### 🎯 Affinity Configuration

The chart provides flexible ways to configure pod affinity rules, including automatic soft anti-affinity and custom node affinity settings.

<details>
<summary>Automatic Soft Anti-Affinity</summary>

Enable automatic soft anti-affinity to spread pods across nodes:

```yaml
deployments:
  my-app:
    autoCreateSoftAntiAffinity: true
```

This will automatically create a podAntiAffinity rule that attempts to schedule pods on different nodes with a preferred (soft) constraint.
</details>

<details>
<summary>Custom Node Affinity</summary>

Configure custom node affinity rules for specific node selection:

```yaml
deployments:
  my-app:
    nodeSelector:
      node-type: worker
      kubernetes.io/os: linux
    
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: kubernetes.io/instance-type
                  operator: In
                  values:
                    - m5.large
                    - m5.xlarge
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
                - key: node-role
                  operator: In
                  values:
                    - worker
```
</details>

<details>
<summary>Combined Affinity Rules</summary>

You can combine different types of affinity rules:

```yaml
deployments:
  my-app:
    autoCreateSoftAntiAffinity: true
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: node-type
                  operator: In
                  values:
                    - worker
      podAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/name: cache
              topologyKey: kubernetes.io/hostname
```

Note: When `autoCreateSoftAntiAffinity` is enabled along with custom pod anti-affinity rules, both will be merged in the final configuration.
</details>

<details>
<summary>PDB Configuration</summary>

```yaml
deployments:
  my-app:
    autoCreatePdb: true
    pdbConfig:
      minAvailable: 1
      # or
      maxUnavailable: 1
```
</details>

## ⚙️ Global Settings

### Deployments General Configuration

<details>
<summary>Global Deployment Settings</summary>

The `deploymentsGeneral` section allows you to set default configurations that will be applied to all deployments:

```yaml
deploymentsGeneral:
  # Default security context for all pods
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000

  # Default node selection
  nodeSelector:
    kubernetes.io/os: linux
    node-type: application

  # Default tolerations
  tolerations:
    - key: "node-role"
      operator: "Equal"
      value: "infrastructure"
      effect: "NoSchedule"

  # Default probes configuration
  probes:
    livenessProbe:
      httpGet:
        path: /health
        port: http
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: http
      initialDelaySeconds: 5
      periodSeconds: 10
    startupProbe:
      httpGet:
        path: /startup
        port: http
      failureThreshold: 30
      periodSeconds: 10

  # Default affinity rules
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            topologyKey: "kubernetes.io/hostname"

  # Default lifecycle hooks
  lifecycle:
    preStop:
      exec:
        command: ["/bin/sh", "-c", "sleep 10"]
```

Each deployment can override these settings with its own configuration.
</details>

### Generic Settings

<details>
<summary>Generic Configuration</summary>

The `generic` section contains global settings that affect multiple resource types:

```yaml
generic:
  # Global image pull secrets
  extraImagePullSecrets:
    - name: registry-secret
    - name: private-registry

  # Ingress default settings
  ingressesGeneral:
    annotations:
      nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    domain: example.com
    ingressClassName: nginx

  # Service monitor defaults
  serviceMonitorGeneral:
    labels:
      prometheus: kube-prometheus
    interval: 30s
```
</details>

## ❓ FAQ

<details>
<summary>How do I expose my application externally?</summary>

Use autoCreateIngress with appropriate host configuration:
```yaml
deployments:
  my-app:
    autoCreateIngress: true
    autoCreateCertificate: true  # If you need HTTPS
    ingress:
      hosts:
        - host: myapp.example.com
          paths:
            - path: /
              pathType: Prefix
```
Or use a subdomain in cases where a global domain has been provided.
```yaml
generic:
  ingressesGeneral:
    domain: example.com
    ingressClassName: alb

deployments:
  myapp:
    autoCreateIngress: true
    ingress:
      hosts:
        - subdomain: api  # Will be api.example.com
          paths:
            - path: /
              pathType: Prefix

deployments:
  myapp2:
    autoCreateIngress: true
    ingress:
      hosts:
        - host: custom.domain.com  # An explicitly specified host takes precedence.
          paths:
            - path: /
              pathType: Prefix
        - host: ""  # Will use global domain.
          paths:
            - path: /
              pathType: Prefix
        - subdomain: api  # Will be api.example.com
          paths:
            - path: /
              pathType: Prefix
```
</details>

<details>
<summary>How do I configure database migrations?</summary>

Enable migrations in your deployment:
```yaml
deployments:
  my-app:
    migrations:
      enabled: true
      args:
        - "migrate"
        - "up"
      backoffLimit: 3
```
</details>

<details>
<summary>How do I scale my application?</summary>

Use HPA configuration:
```yaml
deployments:
  my-app:
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
</details>

<details>
<summary>How do I add custom annotations to my resources?</summary>

Add annotations under the specific resource:
```yaml
deployments:
  my-app:
    annotations:
      custom.annotation/value: "my-value"
    podAnnotations:
      custom.pod/value: "pod-value"
```
</details>

<details>
<summary>How do I configure persistent storage?</summary>

Create PVC and add volume configuration:
```yaml
persistentVolumeClaims:
  data-storage:
    accessModes:
      - ReadWriteOnce
    size: 10Gi

deployments:
  my-app:
    volumes:
      - name: data
        persistentVolumeClaim:
          claimName: data-storage
    containers:
      main:
        volumeMounts:
          - name: data
            mountPath: /data
```
</details>


<details>
<summary>PDB Configuration</summary>

```yaml
deployments:
  my-app:
    autoCreatePdb: true
    pdbConfig:
      minAvailable: 1
      # or
      maxUnavailable: 1
```
</details>