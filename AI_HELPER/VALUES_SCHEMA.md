# KS Universal Chart: Values Schema Reference

This reference guide documents the complete schema of the values.yaml file for the ks-universal Helm chart. It is designed for AI agents to understand all available configuration options.

## Top-Level Structure

```yaml
# Global settings
generic:
  # Settings here affect all resources

# Secret references
secretRefs:
  # Secret references for container environment variables

# Deployments
deployments:
  # Deployment configurations

# Services
services:
  # Service configurations

# CronJobs
cronJobs:
  # CronJob configurations

# Jobs
jobs:
  # Job configurations

# DexAuthenticator
dexAuthenticators:
  # DexAuthenticator configurations

# ConfigMaps
configs:
  # ConfigMap configurations

# PersistentVolumeClaims
persistentVolumeClaims:
  # PVC configurations

# HorizontalPodAutoscalers
hpas:
  # HPA configurations directly (also can be auto-generated)
```

## Generic Settings

The `generic` section contains global settings that apply to multiple resources:

```yaml
generic:
  # General settings for deployments
  deploymentsGeneral:
    securityContext: {}
    nodeSelector: {}
    tolerations: []
    affinity: {}
    probes:
      livenessProbe: {}
      readinessProbe: {}
      startupProbe: {}
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxUnavailable: 1
        maxSurge: 1
    parallelism: 1    # For Job resources
    completions: 1    # For Job resources
    autoCreateSoftAntiAffinity: true
  
  # General settings for ingress resources
  ingressesGeneral:
    annotations: {}
    ingressClassName: "nginx"
    domain: "example.com"  # Global domain for all ingresses
    tls: []
  
  # General settings for service monitors
  serviceMonitorGeneral:
    interval: "30s"
    scrapeTimeout: "10s"
    labels:
      prometheus: "default"
  
  # General settings for DexAuthenticator
  dexAuthenticatorGeneral:
    namespace: "default"
    name: "dex"
  
  # Extra pull secrets
  extraImagePullSecrets:
    - name: "registry-credentials"
```

## Secret References

The `secretRefs` section defines environment variables derived from secrets:

```yaml
secretRefs:
  database:  # Reference name used in containers
    - name: DB_HOST
      secretKeyRef:
        name: db-credentials  # Secret name
        key: host             # Secret key
    - name: DB_PASSWORD
      secretKeyRef:
        name: db-credentials
        key: password
  
  storage:  # Another reference
    - name: STORAGE_ENDPOINT
      secretKeyRef:
        name: storage-credentials
        key: endpoint
    - name: STORAGE_KEY
      secretKeyRef:
        name: storage-credentials
        key: access_key
```

## Deployments

The `deployments` section defines deployment resources:

```yaml
deployments:
  app-name:  # Name of the deployment
    replicas: 1  # Number of replicas
    
    # Container definitions
    containers:
      main:  # Container name
        image: "nginx"  # Container image
        imageTag: "latest"  # Image tag
        
        # Container ports
        ports:
          http:  # Port name
            containerPort: 80  # Container port
            servicePort: 8080  # Optional: custom service port
            protocol: TCP  # Protocol (default: TCP)
          
          http-metrics:  # Special port name for metrics
            containerPort: 9090
        
        # Environment variables
        env:
          - name: ENV_VAR
            value: "value"
          - name: SECRET_VAR
            valueFrom:
              secretKeyRef:
                name: secret-name
                key: secret-key
        
        # Reference to predefined secret references
        secretRefs:
          - database  # Uses the database secretRef defined in the root secretRefs
        
        # Environment variables from ConfigMaps or Secrets
        envFrom:
          - type: configMap  # configMap or secret
            configName: config-name
        
        # Resource requirements
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "100m"
            memory: "128Mi"
        
        # Container security context
        securityContext:
          runAsUser: 1000
          runAsNonRoot: true
          readOnlyRootFilesystem: true
        
        # Probes
        probes:
          livenessProbe:
            httpGet:
              path: /healthz
              port: http  # Can reference port name
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          startupProbe:
            httpGet:
              path: /startupz
              port: http
            failureThreshold: 30
            periodSeconds: 10
        
        # Volume mounts
        volumeMounts:
          - name: config-volume
            mountPath: /etc/config
            readOnly: true
          - name: data-volume
            mountPath: /data
        
        # Container lifecycle hooks
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "echo 'PostStart hook'"]
          preStop:
            exec:
              command: ["/bin/sh", "-c", "echo 'PreStop hook'"]
        
        # Container commands
        command: ["/bin/sh", "-c"]
        args: ["nginx -g 'daemon off;'"]
    
    # Pod-level volumes
    volumes:
      - name: config-volume
        configMap:
          name: app-config
      - name: data-volume
        persistentVolumeClaim:
          claimName: data-pvc
    
    # Pod security context
    securityContext:
      fsGroup: 2000
    
    # Node selector
    nodeSelector:
      kubernetes.io/os: linux
    
    # Pod tolerations
    tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"
    
    # Affinity settings
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: "kubernetes.io/e2e-az-name"
                  operator: "In"
                  values: ["e2e-az1", "e2e-az2"]
    
    # Auto-creation flags
    autoCreateService: true
    autoCreateIngress: true
    autoCreatePdb: true
    autoCreateServiceMonitor: true
    autoCreateServiceAccount: true
    autoCreateCertificate: true
    autoCreateSoftAntiAffinity: true
    
    # Service type (when using autoCreateService)
    serviceType: ClusterIP
    
    # PDB configuration (when using autoCreatePdb)
    pdbConfig:
      maxUnavailable: 1
      # OR
      # minAvailable: 2
    
    # ServiceMonitor configuration (when using autoCreateServiceMonitor)
    serviceMonitor:
      interval: "15s"
      scrapeTimeout: "10s"
      path: "/metrics"
      # For more complex configurations:
      endpoints:
        - port: http-metrics
          path: /metrics
          interval: "15s"
          scrapeTimeout: "10s"
      labels:
        prometheus: "app-prometheus"
    
    # Ingress configuration (when using autoCreateIngress)
    ingress:
      annotations:
        nginx.ingress.kubernetes.io/ssl-redirect: "true"
      ingressClassName: "nginx"
      hosts:
        - host: "app.example.com"  # Explicit host
          paths:
            - path: "/"
              pathType: "Prefix"
              port: 80        # Use specific port number
              # OR
              # portName: http  # Use port by name
        - subdomain: "api"    # Will become api.example.com if generic.ingressesGeneral.domain is set
          paths:
            - path: "/api"
              pathType: "Prefix"
      tls:
        - secretName: app-tls
          hosts:
            - "app.example.com"
      # Optional DexAuthenticator integration
      dexAuthenticator:
        enabled: true
    
    # Certificate configuration (when using autoCreateCertificate)
    certificate:
      # Either issuer or clusterIssuer should be set
      issuer: "letsencrypt-staging"
      # OR
      # clusterIssuer: "letsencrypt-prod"
    
    # ServiceAccount configuration (when using autoCreateServiceAccount)
    serviceAccountConfig:
      annotations:
        eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/app-role"
    
    # Annotations for the deployment
    annotations:
      app.kubernetes.io/version: "1.0.0"
    
    # Pod annotations
    podAnnotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "9090"
    
    # Deployment strategy
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 1
        maxUnavailable: 0
    
    # Namespace for the deployment (defaults to Release.Namespace)
    namespace: "custom-namespace"
```

## Services

The `services` section defines custom service resources:

```yaml
services:
  custom-service:  # Service name
    type: ClusterIP  # Service type (ClusterIP, NodePort, LoadBalancer, ExternalName)
    
    # Port definitions
    ports:
      - name: http  # Port name
        port: 80    # Service port
        targetPort: 8080  # Target port in the container
        # Optional for NodePort
        nodePort: 30080   # Node port for NodePort service type
        protocol: TCP     # Protocol (default: TCP)
      
      - name: https
        port: 443
        targetPort: 8443
```

## CronJobs

The `cronJobs` section defines CronJob resources:

```yaml
cronJobs:
  backup-job:  # CronJob name
    schedule: "0 2 * * *"  # Cron schedule expression
    
    # Optional fields
    concurrencyPolicy: Forbid  # Allow, Forbid, or Replace
    failedJobsHistoryLimit: 3  # How many failed jobs to keep
    successfulJobsHistoryLimit: 3  # How many successful jobs to keep
    startingDeadlineSeconds: 60  # Deadline for starting jobs
    suspend: false  # Whether to suspend job execution
    
    # Container configurations
    containers:
      backup:  # Container name
        image: "backup-tool"
        imageTag: "1.0.0"
        command: ["/bin/sh", "-c", "backup.sh"]
        env:
          - name: BACKUP_DIR
            value: "/backup"
        # All container options from deployments are available
    
    # Pod-level configurations
    volumes: []
    nodeSelector: {}
    tolerations: []
    affinity: {}
    securityContext: {}
    serviceAccountName: "cronjob-sa"
    restartPolicy: OnFailure  # Always, OnFailure, Never
```

## Jobs

The `jobs` section defines Job resources:

```yaml
jobs:
  migration-job:  # Job name
    
    # Optional fields
    parallelism: 1  # How many pods to run in parallel
    completions: 1  # How many successful completions are needed
    backoffLimit: 6  # Number of retries before considering failed
    activeDeadlineSeconds: 600  # Time limit for job
    ttlSecondsAfterFinished: 100  # Time to keep completed job
    
    # Container configurations
    containers:
      migration:  # Container name
        image: "migration-tool"
        imageTag: "1.0.0"
        command: ["/bin/sh", "-c", "migrate.sh"]
        # All container options from deployments are available
    
    # Pod-level configurations
    volumes: []
    nodeSelector: {}
    tolerations: []
    affinity: {}
    securityContext: {}
    serviceAccountName: "job-sa"
    restartPolicy: OnFailure  # Always, OnFailure, Never
```

## DexAuthenticator

The `dexAuthenticators` section defines DexAuthenticator resources:

```yaml
dexAuthenticators:
  main:  # DexAuthenticator name
    
    # Dex server configuration
    dexServer:
      url: "https://dex.example.com"
      clientID: "example-app"
      clientSecret: "secret"
    
    # Cookie configuration
    cookie:
      name: "dex_auth_cookie"
      expiry: "24h"
      secret: "random-secret-key"
      secure: true
      domain: ".example.com"
    
    # Endpoint configuration
    endpoints:
      callback: "/dex-authenticator/callback"
      login: "/dex-authenticator/login"
      auth: "/dex-authenticator/auth"
      logout: "/dex-authenticator/logout"
      sign_in: "/dex-authenticator/sign_in"
    
    # Container configuration
    replicas: 1
    image: "dexidp/dex-authenticator"
    imageTag: "latest"
    containerPort: 8080
    
    # Resources configuration
    resources:
      limits:
        cpu: "500m"
        memory: "512Mi"
      requests:
        cpu: "100m"
        memory: "128Mi"
    
    # Ingress configuration
    ingress:
      enabled: true
      annotations: {}
      ingressClassName: "nginx"
      host: "auth.example.com"
      tls:
        enabled: true
        secretName: "auth-tls"
    
    # Additional environment variables
    extraEnv: []
```

## ConfigMaps

The `configs` section defines ConfigMap resources:

```yaml
configs:
  app-config:  # ConfigMap name
    data:
      config.json: |
        {
          "key": "value",
          "nested": {
            "key": "value"
          }
        }
      app.properties: |
        property1=value1
        property2=value2
      
      # Binary data (base64 encoded)
      binaryData:
        "logo.png": "SGVsbG8gV29ybGQ="
```

## PersistentVolumeClaims

The `persistentVolumeClaims` section defines PVC resources:

```yaml
persistentVolumeClaims:
  data-storage:  # PVC name
    accessModes:
      - ReadWriteOnce  # Access modes: ReadWriteOnce, ReadOnlyMany, ReadWriteMany
    
    # Size request
    resources:
      requests:
        storage: 10Gi
    
    # Optional fields
    storageClassName: "standard"  # Storage class
    volumeMode: Filesystem  # Filesystem or Block
    selector:
      matchLabels:
        type: ssd
```

## HorizontalPodAutoscalers

The `hpas` section defines HPA resources:

```yaml
hpas:
  app-hpa:  # HPA name
    scaleTargetRef:
      apiVersion: apps/v1
      kind: Deployment
      name: app-name
    
    minReplicas: 1
    maxReplicas: 10
    
    # Metrics for scaling
    metrics:
      - type: Resource
        resource:
          name: cpu
          target:
            type: Utilization
            averageUtilization: 80
      
      - type: Resource
        resource:
          name: memory
          target:
            type: Utilization
            averageUtilization: 80
      
      # Pods metric
      - type: Pods
        pods:
          metric:
            name: packets-per-second
          target:
            type: AverageValue
            averageValue: "1k"
      
      # Object metric
      - type: Object
        object:
          metric:
            name: requests-per-second
          describedObject:
            apiVersion: networking.k8s.io/v1
            kind: Ingress
            name: app-ingress
          target:
            type: Value
            value: "10k"
    
    # Behavior configuration
    behavior:
      scaleDown:
        stabilizationWindowSeconds: 300
        policies:
          - type: Percent
            value: 10
            periodSeconds: 60
      scaleUp:
        stabilizationWindowSeconds: 60
        policies:
          - type: Percent
            value: 100
            periodSeconds: 60
```

## Deployment Auto-Creation Features

Auto-creation flags control the automatic generation of related resources:

```yaml
deployments:
  example:
    # ...container configuration...
    
    # Service auto-creation
    autoCreateService: true
    serviceType: ClusterIP  # Service type for auto-created service
    
    # Ingress auto-creation
    autoCreateIngress: true
    ingress:
      # Ingress configuration for auto-created ingress
    
    # PDB auto-creation
    autoCreatePdb: true
    pdbConfig:
      maxUnavailable: 1
      # OR
      # minAvailable: 2
    
    # ServiceMonitor auto-creation
    autoCreateServiceMonitor: true
    serviceMonitor:
      # ServiceMonitor configuration for auto-created ServiceMonitor
    
    # ServiceAccount auto-creation
    autoCreateServiceAccount: true
    serviceAccountConfig:
      # ServiceAccount configuration for auto-created ServiceAccount
    
    # Certificate auto-creation
    autoCreateCertificate: true
    certificate:
      # Certificate configuration for auto-created Certificate
```

## Value Processing Behaviors

Understanding how values are processed is important:

1. **Inheritance**: Resources inherit settings from global configuration
2. **Defaults**: Default values are applied when not specified
3. **Overrides**: Local settings override global settings
4. **Templating**: String values can contain Go templates
5. **Environment Variables**: Can be specified directly or via secretRefs
6. **DomainConstruction**: Domains can be constructed from subdomain and global domain

## Template Logic and Helpers

The chart uses several helper functions to process values:

1. **deploymentDefaults**: Merges deployment config with global defaults
2. **ingressDefaults**: Merges ingress config with global defaults
3. **processAffinity**: Processes affinity settings and nodeSelector
4. **containers**: Generates container specifications
5. **tplValue**: Processes template expressions in values
6. **hasMetricsPort**: Checks if a metrics port exists
7. **shouldCreateServiceMonitor**: Determines if a ServiceMonitor should be created
8. **computedIngressHost**: Computes the full ingress host name
9. **processSecretRefs**: Processes secret references for environment variables

## Validation Rules

The chart validates values before processing:

1. **Required Fields**: Image, imageTag, etc. are required
2. **Port Ranges**: Ports must be between 1 and 65535
3. **Unique Port Names**: Port names must be unique within a container
4. **PDB Configuration**: Either minAvailable or maxUnavailable must be set
5. **HPA Metrics**: At least one metric must be defined
6. **Secret References**: Must exist and have valid structure

## Common Configurations

### Basic Web Application

```yaml
deployments:
  web-app:
    replicas: 3
    containers:
      app:
        image: "nginx"
        imageTag: "1.21"
        ports:
          http:
            containerPort: 80
    autoCreateService: true
    autoCreateIngress: true
    ingress:
      hosts:
        - subdomain: "web"
          paths:
            - path: "/"
              pathType: "Prefix"
```

### Microservice with Database

```yaml
secretRefs:
  postgres:
    - name: DB_HOST
      secretKeyRef:
        name: postgres-creds
        key: host
    - name: DB_USER
      secretKeyRef:
        name: postgres-creds
        key: username
    - name: DB_PASSWORD
      secretKeyRef:
        name: postgres-creds
        key: password

deployments:
  api-service:
    replicas: 2
    containers:
      api:
        image: "api-service"
        imageTag: "v1.0.0"
        ports:
          http:
            containerPort: 8080
          http-metrics:
            containerPort: 8081
        secretRefs:
          - postgres
        env:
          - name: LOG_LEVEL
            value: "info"
    autoCreateService: true
    autoCreateServiceMonitor: true
```

### Scheduled Backup Job

```yaml
cronJobs:
  backup:
    schedule: "0 0 * * *"
    containers:
      backup:
        image: "backup-tool"
        imageTag: "1.0.0"
        command: ["/bin/sh", "-c", "backup.sh"]
        volumeMounts:
          - name: backup-volume
            mountPath: /backup
    volumes:
      - name: backup-volume
        persistentVolumeClaim:
          claimName: backup-pvc

persistentVolumeClaims:
  backup-pvc:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 10Gi
```

## Schema Validation Rules

When using this chart, be aware of these validation rules:

1. **Required Container Fields**: `image` and `imageTag` are required for all containers
2. **Valid Port Range**: Container ports must be between 1 and 65535
3. **Environment Variables**: Either `value` or `valueFrom` must be specified
4. **PDB Configuration**: Either `minAvailable` or `maxUnavailable` must be specified, not both
5. **HPA Metrics**: At least one metric must be defined with valid configuration
6. **ServiceMonitor Endpoints**: Must have valid port and interval format
7. **Volume Mounts**: Must reference a volume defined in the `volumes` section
8. **Affinity Settings**: Must follow Kubernetes affinity structure
9. **Ingress Paths**: Must have a path and pathType
10. **Secret References**: Must be defined in the top-level `secretRefs` section
``` 