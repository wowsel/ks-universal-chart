# KS Universal Chart: Values Schema Reference

This reference guide documents the complete schema of the values.yaml file for the ks-universal Helm chart. It is designed for AI agents to understand all available configuration options.

## Top-Level Structure

```yaml
# Global deployment settings that apply to all deployments unless overridden
deploymentsGeneral:
  # Global settings for all deployments (jobs, cronjobs, etc.)

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

# Ingresses
ingresses:
  # Ingress configurations

# ConfigMaps and Secrets
configs:
  # ConfigMap and Secret configurations

# PersistentVolumeClaims
persistentVolumeClaims:
  # PVC configurations

# HorizontalPodAutoscalers
hpas:
  # HPA configurations
```

## Deployment General Settings

⚠️ **IMPORTANT**: The `deploymentsGeneral` section is a top-level configuration that applies to ALL deployments, jobs, and cronjobs unless overridden locally. This is different from `generic.deploymentsGeneral` which doesn't exist in the actual implementation.

```yaml
deploymentsGeneral:
  # Pod security context settings applied to all deployments
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  
  # Node selection criteria for pod scheduling
  nodeSelector:
    kubernetes.io/os: linux
  
  # Pod tolerations for scheduling
  tolerations:
    - key: "node-role.kubernetes.io/master"
      operator: "Exists"
      effect: "NoSchedule"
  
  # Pod affinity/anti-affinity settings
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: "kubernetes.io/arch"
                operator: "In"
                values: ["amd64"]
  
  # Default health check probe configurations for all containers
  probes:
    # Liveness probe - determines if the container is running properly
    livenessProbe:
      httpGet:
        path: /health
        port: http
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    
    # Readiness probe - determines if the container is ready to serve traffic
    readinessProbe:
      httpGet:
        path: /ready
        port: http
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 3
      failureThreshold: 3
    
    # Startup probe - determines if the container has started successfully
    startupProbe:
      httpGet:
        path: /startup
        port: http
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 30
  
  # Deployment update strategy configuration
  strategy:
    type: RollingUpdate    # Strategy type: RollingUpdate or Recreate
    rollingUpdate:         # Configuration for RollingUpdate strategy
      maxSurge: 1         # Maximum number of pods that can be created above desired number
      maxUnavailable: 1   # Maximum number of pods that can be unavailable during the update
  
  # Job-specific settings
  parallelism: 1          # Default parallelism for jobs
  completions: 1          # Default completions for jobs
  
  # Auto-creation settings applied to all deployments
  autoCreateSoftAntiAffinity: true  # Automatically create soft anti-affinity rules
```

## Generic Settings

The `generic` section contains global settings that apply to multiple resources:

```yaml
generic:
  # General settings for ingress resources
  ingressesGeneral:
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    ingressClassName: "nginx"
    domain: "example.com"  # Global domain for all ingresses
    tls:
      - secretName: "default-tls"
        hosts:
          - "*.example.com"
  
  # General settings for service monitors
  serviceMonitorGeneral:
    interval: "30s"
    scrapeTimeout: "10s"
    labels:
      prometheus: "default"
  
  # Global DexAuthenticator configuration
  dexAuthenticatorGeneral:
    enabled: true                                   # Enable global DexAuthenticator
    applicationDomain: auth.example.com             # Domain for DexAuthenticator
    applicationIngressClassName: nginx              # Ingress class name
    name: custom-dex                                # Optional: custom name for the authenticator
    namespace: auth-system                          # Optional: namespace for DexAuthenticator
    sendAuthorizationHeader: true                   # Optional: Send Authorization header
    applicationIngressCertificateSecretName: "tls"  # Optional: SSL certificate secret
    keepUsersLoggedInFor: "720h"                    # Optional: Session duration (format: 30m, 1h, 2h30m, 24h)
    allowedGroups:                                  # Optional: Allow only users in these groups
      - everyone
      - admins
    whitelistSourceRanges:                          # Optional: IP whitelisting
      - 10.0.0.0/8
      - 192.168.0.0/16
    additionalApplications:                         # Optional: Additional applications
      - domain: extra-app.example.com
        ingressSecretName: ingress-tls
        ingressClassName: nginx
        signOutURL: "/logout"
        whitelistSourceRanges:
          - 10.0.0.0/8
    nodeSelector:                                   # Optional: NodeSelector for DexAuthenticator pods
      kubernetes.io/os: linux
    tolerations:                                    # Optional: Tolerations for DexAuthenticator pods
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
        effect: "NoSchedule"
    autoCreateCertificate: true                     # Optional: Auto-create SSL certificate
    certificate:                                    # Optional: Certificate configuration
      clusterIssuer: letsencrypt-prod
      # OR
      # issuer: letsencrypt-staging
  
  # Extra pull secrets - applied to all deployments, jobs, and cronjobs
  extraImagePullSecrets:
    - name: "registry-credentials"
    - name: "docker-hub-credentials"
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
            servicePort: 8080  # Optional: custom service port (different from containerPort)
            protocol: TCP  # Protocol (default: TCP)
          
          http-metrics:  # Special port name for metrics (automatically detected by ServiceMonitor)
            containerPort: 9090
            servicePort: 9090  # Optional: custom service port
        
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
        
        # Probes (inherit from deploymentsGeneral if not specified)
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
            subPath: config.yaml  # Optional: mount specific file
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
    
    # Database migrations configuration
    migrations:
      enabled: true                    # Enable database migrations
      backoffLimit: 1                  # Number of retries before considering failed
      parallelism: 1                   # How many migration pods to run in parallel
      completions: 1                   # How many successful completions are needed
      args: ["migrate", "up"]          # Migration command arguments
    
    # Pod-level volumes
    volumes:
      - name: config-volume
        configMap:
          name: app-config
      - name: data-volume
        persistentVolumeClaim:
          claimName: data-pvc
    
    # Pod security context (overrides deploymentsGeneral.securityContext)
    securityContext:
      fsGroup: 2000
    
    # Node selector (overrides deploymentsGeneral.nodeSelector)
    nodeSelector:
      kubernetes.io/os: linux
    
    # Pod tolerations (overrides deploymentsGeneral.tolerations)
    tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"
    
    # Affinity settings (overrides deploymentsGeneral.affinity)
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
    autoCreateSoftAntiAffinity: true   # Create soft anti-affinity rules
    
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
          # Optional: relabeling configurations
          relabelings:
            - sourceLabels: [__meta_kubernetes_pod_name]
              targetLabel: pod_name
          # Optional: metric relabeling configurations
          metricRelabelings:
            - sourceLabels: [__name__]
              regex: 'go_.*'
              action: drop
          # Optional: honor labels and timestamps
          honorLabels: true
          honorTimestamps: true
          # Optional: TLS configuration
          scheme: https
          tlsConfig:
            insecureSkipVerify: true
      labels:
        prometheus: "app-prometheus"
      # Optional: namespace selector
      namespaceSelector:
        matchNames:
          - monitoring
    
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
              # If no port/portName specified, uses first available port
      tls:
        - secretName: app-tls
          hosts:
            - "app.example.com"
      # Optional: DexAuthenticator integration
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
    
    # Deployment strategy (overrides deploymentsGeneral.strategy)
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 1
        maxUnavailable: 0
    
    # Namespace for the deployment (defaults to Release.Namespace)
    namespace: "custom-namespace"
    
    # HPA configuration (embedded in deployment)
    hpa:
      minReplicas: 1
      maxReplicas: 10
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
      # Optional: scaling behavior
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
    
    # Optional: timezone for schedule (requires Kubernetes 1.24+)
    timezone: "America/New_York"  # IANA timezone name
    
    # Optional fields
    concurrencyPolicy: Forbid  # Allow, Forbid, or Replace
    failedJobsHistoryLimit: 3  # How many failed jobs to keep
    successfulJobsHistoryLimit: 3  # How many successful jobs to keep
    startingDeadlineSeconds: 60  # Deadline for starting jobs
    suspend: false  # Whether to suspend job execution
    
    # Job template configuration
    activeDeadlineSeconds: 600  # Time limit for job execution
    backoffLimit: 6  # Number of retries before considering failed
    parallelism: 1  # How many pods to run in parallel
    completions: 1  # How many successful completions are needed
    
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
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        volumeMounts:
          - name: backup-volume
            mountPath: /backup
    
    # Pod-level configurations (inherit from deploymentsGeneral if not specified)
    volumes:
      - name: backup-volume
        persistentVolumeClaim:
          claimName: backup-pvc
    nodeSelector:
      kubernetes.io/os: linux
    tolerations:
      - key: "backup-node"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
    affinity:
      nodeAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
                - key: "node-type"
                  operator: "In"
                  values: ["backup"]
    securityContext:
      runAsUser: 1000
    serviceAccountName: "backup-sa"
    restartPolicy: OnFailure  # Always, OnFailure, Never
    
    # Optional: annotations and labels
    annotations:
      description: "Daily backup job"
    podAnnotations:
      backup.io/type: "database"
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
    ttlSecondsAfterFinished: 100  # Time to keep completed job (cleanup after completion)
    
    # Container configurations
    containers:
      migration:  # Container name
        image: "migration-tool"
        imageTag: "1.0.0"
        command: ["/bin/sh", "-c", "migrate.sh"]
        env:
          - name: DB_HOST
            value: "database.example.com"
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        # All container options from deployments are available
        volumeMounts:
          - name: migration-config
            mountPath: /config
            readOnly: true
    
    # Pod-level configurations (inherit from deploymentsGeneral if not specified)
    volumes:
      - name: migration-config
        configMap:
          name: migration-config
    nodeSelector:
      kubernetes.io/os: linux
    tolerations:
      - key: "migration-node"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: "node-type"
                  operator: "In"
                  values: ["worker"]
    securityContext:
      runAsUser: 1000
      fsGroup: 2000
    serviceAccountName: "migration-sa"
    restartPolicy: OnFailure  # Always, OnFailure, Never
    
    # Optional: annotations and labels
    annotations:
      job.io/type: "database-migration"
    podAnnotations:
      migration.io/version: "v1.0.0"
```

## Ingresses

The `ingresses` section defines standalone ingress resources (separate from deployment auto-created ingresses):

```yaml
ingresses:
  api-gateway:  # Ingress name
    annotations:
      nginx.ingress.kubernetes.io/cors-allow-origin: "*"
      nginx.ingress.kubernetes.io/enable-cors: "true"
    ingressClassName: "nginx"
    hosts:
      - host: "api.example.com"  # Explicit host
        paths:
          - path: "/v1"
            pathType: "Prefix"
            service: backend-api  # Service name to route to
            portName: http        # Port name in the service
            # OR
            # port: 8080          # Specific port number
      - subdomain: "admin"         # Will become admin.example.com if domain is set
        paths:
          - path: "/admin"
            pathType: "Prefix"
            service: admin-service
            portName: admin
      - host: ""                   # Will use domain from generic.ingressesGeneral
        paths:
          - path: "/health"
            pathType: "Exact"
            service: health-check
            portName: http
    tls:
      - secretName: api-tls
        hosts:
          - "api.example.com"
          - "admin.example.com"
    # Optional: DexAuthenticator integration
    dexAuthenticator:
      enabled: true
```

## DexAuthenticator

⚠️ **IMPORTANT**: DexAuthenticator is only supported as a global configuration through `generic.dexAuthenticatorGeneral`. There is no support for standalone DexAuthenticator resources in the current implementation.

The global DexAuthenticator automatically provides authentication for all ingresses that enable it via `dexAuthenticator.enabled: true` in their configuration.

### Configuration

DexAuthenticator is configured through `generic.dexAuthenticatorGeneral` - see the Generic Settings section above for complete configuration options.

### Usage in Ingresses

To enable DexAuthenticator for an ingress (whether auto-created or standalone):

```yaml
# For deployment auto-created ingresses
deployments:
  app:
    autoCreateIngress: true
    ingress:
      dexAuthenticator:
        enabled: true
      # ... other ingress config

# For standalone ingresses  
ingresses:
  api:
    dexAuthenticator:
      enabled: true
    # ... other ingress config
```

## ConfigMaps

The `configs` section defines ConfigMap resources:

```yaml
configs:
  # Application configuration as ConfigMap
  app-config:
    type: configMap     # Type can be 'configMap' or 'secret'
    data:
      config.yaml: |    # Configuration file content
        environment: production
        log_level: info
        features:
          feature1: true
          feature2: false
      app.properties: |
        property1=value1
        property2=value2
      # Simple key-value pairs
      API_ENDPOINT: "https://api.example.com"
      DEBUG_MODE: "false"
    # Optional: binary data for ConfigMaps (base64 encoded)
    binaryData:
      logo.png: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
  
  # Application secrets
  app-secrets:
    type: secret       # Creates a Kubernetes Secret
    data:
      API_KEY: "your-api-key"           # Will be base64 encoded automatically
      DB_PASSWORD: "your-db-password"    # Will be base64 encoded automatically
      # Multi-line secrets
      private-key.pem: |
        -----BEGIN PRIVATE KEY-----
        MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7...
        -----END PRIVATE KEY-----
    # Optional: binary data for Secrets (base64 encoded)
    binaryData:
      certificate.p12: "MIIKCAIBAzCCCcMGCSqGSIb3DQEHAaCCCbQEggmwMIIJrDCCBX..."
  
  # Configuration with external ConfigMap reference
  external-config:
    type: configMap
    data:
      # Reference to external config
      external-api.yaml: |
        {{- .Values.externalConfig | toYaml | nindent 8 }}
      # Template variables are supported
      app-version: "{{ .Chart.AppVersion }}"
      release-name: "{{ .Release.Name }}"
```

**Important Notes:**
- For `type: secret`, all values in `data` are automatically base64 encoded by Helm
- For `type: configMap`, values are stored as plain text
- Binary data should be pre-encoded in base64 format
- Template expressions using `{{ }}` are supported in values
- ConfigMaps and Secrets are created with Helm hooks to ensure they're available before deployments

## PersistentVolumeClaims

The `persistentVolumeClaims` section defines PVC resources:

```yaml
persistentVolumeClaims:
  data-storage:  # PVC name
    accessModes:
      - ReadWriteOnce  # Access modes: ReadWriteOnce, ReadOnlyMany, ReadWriteMany
    
    # Size request (use 'size' not 'resources.requests.storage')
    size: 10Gi
    
    # Optional fields
    storageClassName: "standard"  # Storage class
    volumeMode: Filesystem        # Filesystem or Block
    
    # Optional: resource selector
    selector:
      matchLabels:
        type: ssd
        environment: production
      matchExpressions:
        - key: tier
          operator: In
          values: ["cache"]
    
    # Optional: annotations
    annotations:
      volume.kubernetes.io/storage-provisioner: "kubernetes.io/aws-ebs"
      volume.beta.kubernetes.io/storage-class: "gp2"
  
  # Example: High-performance storage
  cache-storage:
    accessModes:
      - ReadWriteOnce
    size: 100Gi
    storageClassName: "fast-ssd"
    selector:
      matchLabels:
        performance: "high"
  
  # Example: Shared storage
  shared-storage:
    accessModes:
      - ReadWriteMany
    size: 1Ti
    storageClassName: "nfs"
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
    
    # Soft Anti-Affinity auto-creation  
    autoCreateSoftAntiAffinity: true
```

## Configuration Inheritance and Priority

Understanding how values are processed and inherited is crucial:

### 1. Inheritance Hierarchy (Lowest to Highest Priority)

1. **Chart Defaults** - Built-in defaults from the chart
2. **`deploymentsGeneral`** - Global settings for all deployments, jobs, and cronjobs
3. **`generic.*General`** - Specific global settings (ingressesGeneral, serviceMonitorGeneral, etc.)
4. **Local Resource Configuration** - Settings directly in the deployment/job/cronjob

### 2. Key Inheritance Rules

**Deployments, Jobs, CronJobs:**
- Inherit `securityContext`, `nodeSelector`, `tolerations`, `affinity` from `deploymentsGeneral`
- Inherit `probes` configurations from `deploymentsGeneral` if not specified in containers
- Inherit `strategy`, `parallelism`, `completions` from `deploymentsGeneral`
- Local settings override global settings

**Ingresses:**
- Inherit `annotations`, `ingressClassName`, `tls` from `generic.ingressesGeneral`
- Support automatic domain construction: `subdomain` + `generic.ingressesGeneral.domain`
- Local settings override inherited settings

**ServiceMonitors:**
- Inherit `interval`, `scrapeTimeout`, `labels` from `generic.serviceMonitorGeneral`
- Automatically detect `http-metrics` port or use first available port
- Local settings override inherited settings

**DexAuthenticator:**
- Global configuration only through `generic.dexAuthenticatorGeneral`
- Applied to ingresses via `dexAuthenticator.enabled: true`

### 3. Special Processing Behaviors

**Port Handling:**
- Container ports support both `containerPort` and optional `servicePort`
- ServiceMonitor automatically detects `http-metrics` port name
- Auto-created services use `servicePort` if specified, otherwise `containerPort`

**Domain Construction:**
```yaml
# If generic.ingressesGeneral.domain = "example.com"
ingress:
  hosts:
    - subdomain: "api"          # Results in: api.example.com
    - host: "custom.domain.com" # Results in: custom.domain.com
    - host: ""                  # Results in: example.com
```

**Secret References:**
- Global `secretRefs` can be referenced by name in container `secretRefs` lists
- Automatically merged with container `env` variables

**NodeSelector to NodeAffinity Conversion:**
- `nodeSelector` entries are automatically converted to `nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution`
- Existing `affinity` configuration is preserved and merged

**Soft Anti-Affinity:**
- When `autoCreateSoftAntiAffinity: true`, automatically adds pod anti-affinity rules
- Uses `app.kubernetes.io/component: <deployment-name>` selector
- Only applied if no existing `podAntiAffinity` is configured

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

The chart validates values before processing to catch common errors:

### Required Fields
1. **Container Configuration**: `image` and `imageTag` are required for all containers
2. **Port Configuration**: Ports must be between 1 and 65535, names must be unique within container
3. **Environment Variables**: Either `value` or `valueFrom` must be specified
4. **HPA Configuration**: At least one metric must be defined with valid configuration

### PDB Rules
- Either `minAvailable` or `maxUnavailable` must be specified, not both
- Values can be numbers or percentage strings (e.g., "50%")

### ServiceMonitor Rules
- Port must be a valid port name or number
- Time intervals must be valid duration format (e.g., "30s", "1m", "1h")
- TLS configuration must be properly structured

### Ingress Rules
- Host validation for FQDN format
- Subdomain validation for DNS label format
- Path and pathType are required for each path
- Either host, subdomain, or global domain must be provided

### DexAuthenticator Rules
- Global DexAuthenticator requires `applicationDomain` and `applicationIngressClassName`
- Session duration format: "30m", "1h", "2h30m", "24h"
- Domain validation for additional applications

### Secret References Rules
- Referenced secretRefs must exist in the global `secretRefs` section
- Each secretRef entry must have `name` and `secretKeyRef` with `name` and `key`

## Template Logic and Helpers

The chart uses several helper functions to process values:

1. **deploymentDefaults**: Merges deployment config with `deploymentsGeneral` defaults
2. **ingressDefaults**: Merges ingress config with `generic.ingressesGeneral` defaults  
3. **processAffinity**: Processes affinity settings, converts nodeSelector, adds soft anti-affinity
4. **containers**: Generates container specifications with secret refs and env processing
5. **tplValue**: Processes template expressions in values
6. **hasMetricsPort**: Checks if a metrics port exists in containers
7. **findMetricsPort**: Finds the appropriate metrics port (prefers "http-metrics")
8. **shouldCreateServiceMonitor**: Determines if a ServiceMonitor should be created
9. **computedIngressHost**: Computes the full ingress host name from subdomain/host/domain
10. **dexAnnotations**: Generates DexAuthenticator nginx annotations
11. **processSecretRefs**: Processes secret references for environment variables

## Important Notes for AI Agents

When migrating existing Helm charts to ks-universal, consider these key points:

### 1. Structure Mapping
- **deployments** → Main application workloads
- **cronJobs** → Scheduled tasks
- **jobs** → One-time tasks (including migrations)
- **configs** → Both ConfigMaps and Secrets
- **ingresses** → Standalone ingresses (separate from auto-created ones)

### 2. Auto-Creation Benefits
- Use `autoCreateService`, `autoCreateIngress`, `autoCreatePdb` etc. to reduce boilerplate
- Auto-created resources inherit settings and follow naming conventions
- Certificate management via `autoCreateCertificate` with cert-manager integration

### 3. Global Settings Strategy
- Put common settings in `deploymentsGeneral` (security, node selection, probes)
- Use `generic.ingressesGeneral.domain` for consistent domain handling
- Configure global DexAuthenticator once, enable per-ingress

### 4. Migration Checklist
- [ ] Move common container settings to `deploymentsGeneral`
- [ ] Convert standalone resources to auto-creation where possible
- [ ] Consolidate domain configuration in `generic.ingressesGeneral.domain`
- [ ] Use `secretRefs` for shared environment variables
- [ ] Enable soft anti-affinity with `autoCreateSoftAntiAffinity: true`

### 5. Common Pitfalls
- Don't use `generic.deploymentsGeneral` - use top-level `deploymentsGeneral`
- Don't define standalone `dexAuthenticators` - use `generic.dexAuthenticatorGeneral`
- Remember to use `size` not `resources.requests.storage` for PVCs
- Use `servicePort` when you need different service and container ports

### 6. Template Functions Available
- `{{ .Chart.AppVersion }}` - Application version
- `{{ .Release.Name }}` - Helm release name
- `{{ .Release.Namespace }}` - Target namespace
- All Go template functions and Sprig functions are available

## Validation Rules

The chart validates values before processing to catch common errors:

### Required Fields
1. **Container Configuration**: `image` and `imageTag` are required for all containers
2. **Port Configuration**: Ports must be between 1 and 65535, names must be unique within container
3. **Environment Variables**: Either `value` or `valueFrom` must be specified
4. **HPA Configuration**: At least one metric must be defined with valid configuration

### PDB Rules
- Either `minAvailable` or `maxUnavailable` must be specified, not both
- Values can be numbers or percentage strings (e.g., "50%")

### ServiceMonitor Rules
- Port must be a valid port name or number
- Time intervals must be valid duration format (e.g., "30s", "1m", "1h")
- TLS configuration must be properly structured

### Ingress Rules
- Host validation for FQDN format
- Subdomain validation for DNS label format
- Path and pathType are required for each path
- Either host, subdomain, or global domain must be provided

### DexAuthenticator Rules
- Global DexAuthenticator requires `applicationDomain` and `applicationIngressClassName`
- Session duration format: "30m", "1h", "2h30m", "24h"
- Domain validation for additional applications

### Secret References Rules
- Referenced secretRefs must exist in the global `secretRefs` section
- Each secretRef entry must have `name` and `secretKeyRef` with `name` and `key`

## Template Logic and Helpers

The chart uses several helper functions to process values:

1. **deploymentDefaults**: Merges deployment config with `deploymentsGeneral` defaults
2. **ingressDefaults**: Merges ingress config with `generic.ingressesGeneral` defaults  
3. **processAffinity**: Processes affinity settings, converts nodeSelector, adds soft anti-affinity
4. **containers**: Generates container specifications with secret refs and env processing
5. **tplValue**: Processes template expressions in values
6. **hasMetricsPort**: Checks if a metrics port exists in containers
7. **findMetricsPort**: Finds the appropriate metrics port (prefers "http-metrics")
8. **shouldCreateServiceMonitor**: Determines if a ServiceMonitor should be created
9. **computedIngressHost**: Computes the full ingress host name from subdomain/host/domain
10. **dexAnnotations**: Generates DexAuthenticator nginx annotations
11. **processSecretRefs**: Processes secret references for environment variables
``` 