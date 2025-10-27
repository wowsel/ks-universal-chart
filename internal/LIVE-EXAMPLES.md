# KS Universal Chart: Live Examples

This document contains real-world examples of using the ks-universal chart, anonymized and simplified to showcase best practices and common patterns.

## Project Structure

### Chart.yaml - Using ks-universal as Dependency

```yaml
apiVersion: v2
name: microservice-platform
description: A Helm chart for microservices platform
type: application
version: 0.1.0
appVersion: "1.0.0"
dependencies:
  - name: ks-universal
    version: "v0.2.17"
    repository: https://wowsel.github.io/ks-universal-chart
    export-values:
      - parent: werf
        child: werf
```

## Example 1: Microservices Platform with Shared Configuration

### Main values.yaml

```yaml
ks-universal:
  # Global deployment settings
  deploymentsGeneral:
    nodeSelector:
      workload-type: "microservices"
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      fsGroup: 1000

  # Global configurations
  generic:
    ingressesGeneral:
      annotations:
        nginx.ingress.kubernetes.io/enable-cors: "true"
        nginx.ingress.kubernetes.io/rewrite-target: /$1
      ingressClassName: nginx
    serviceMonitorGeneral:
      labels:
        prometheus: main
        release: kube-prometheus-stack

  # Shared configurations for all services
  configs:
    # Common configuration shared by all services
    platform-config:
      type: configMap
      data:
        LOG_LEVEL: "info"
        DATABASE_PORT: "5432"
        DATABASE_USER: "app_user"
        DATABASE_NAME: "platform"
        DATABASE_USE_SSL: "true"
        REDIS_PORT: "6379"
        REDIS_TLS: "false"
        MESSAGE_QUEUE_PORT: "5672"
        MESSAGE_QUEUE_VHOST: "platform"
        STORAGE_ENDPOINT: "https://storage.example.com"
        STORAGE_REGION: "us-east-1"
        STORAGE_BUCKET_NAME: "platform-data"
    
    # Provider-specific configurations
    platform-config-provider-a:
      type: configMap
      data:
        FEATURE_LEVEL: "premium"
        RATE_LIMIT: "1000"
    
    platform-config-provider-b:
      type: configMap
      data:
        FEATURE_LEVEL: "basic"
        RATE_LIMIT: "500"

  # Shared secrets configuration
  secretRefs:
    shared-secrets:
      - name: REDIS_PASSWORD
        secretKeyRef:
          name: platform-secrets
          key: redis-password
      - name: DATABASE_PASSWORD
        secretKeyRef:
          name: platform-secrets
          key: database-password
      - name: MESSAGE_QUEUE_PASSWORD
        secretKeyRef:
          name: platform-secrets
          key: rabbitmq-password
      - name: STORAGE_SECRET_KEY
        secretKeyRef:
          name: platform-secrets
          key: storage-secret-key
      - name: MONITORING_TOKEN
        secretKeyRef:
          name: platform-secrets
          key: monitoring-token

  # Microservices deployments
  deployments:
    # API Gateway Service - Provider A
    api-gateway-provider-a:
      autoCreateService: true
      autoCreateServiceMonitor: true
      autoCreatePdb: true
      pdbConfig:
        minAvailable: 1
      replicas: 2
      containers:
        main:
          image: "{{ $.Values.werf.repo }}"
          imageTag: "{{ $.Values.werf.tag.apiGateway }}"
          args:
            - "gateway:start"
          ports:
            http:
              containerPort: 8080
              protocol: TCP
          probes:
            livenessProbe:
              httpGet:
                path: /api/provider-a/health
                port: http
              initialDelaySeconds: 10
              timeoutSeconds: 5
          lifecycle:
            preStop:
              httpGet:
                path: /api/provider-a/shutdown
                port: http
          resources:
            limits:
              memory: "2048Mi"
            requests:
              cpu: "500m"
              memory: "1024Mi"
          env:
            - name: PORT
              value: "8080"
            - name: DEPLOY_DATE
              value: "{{ now | unixEpoch }}"
            - name: SERVICE_NAME
              value: "api-gateway-provider-a"
            - name: MONITORING_DSN
              value: "https://monitoring.example.com/project/1"
            - name: PROVIDER_TYPE
              value: "provider-a"
            - name: NODE_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
          envFrom:
            - type: configMap
              configName: platform-config
            - type: configMap
              configName: platform-config-provider-a
          secretRefs:
            - shared-secrets
      serviceMonitor:
        endpoints:
          - port: http
            path: /api/provider-a/metrics

    # API Gateway Service - Provider B (similar structure)
    api-gateway-provider-b:
      autoCreateService: true
      autoCreateServiceMonitor: true
      autoCreatePdb: true
      pdbConfig:
        minAvailable: 1
      replicas: 2
      containers:
        main:
          image: "{{ $.Values.werf.repo }}"
          imageTag: "{{ $.Values.werf.tag.apiGateway }}"
          args:
            - "gateway:start"
          ports:
            http:
              containerPort: 8080
              protocol: TCP
          probes:
            livenessProbe:
              httpGet:
                path: /api/provider-b/health
                port: http
              initialDelaySeconds: 10
              timeoutSeconds: 5
          resources:
            limits:
              memory: "2560Mi"
            requests:
              cpu: "500m"
              memory: "2048Mi"
          env:
            - name: PORT
              value: "8080"
            - name: SERVICE_NAME
              value: "api-gateway-provider-b"
            - name: PROVIDER_TYPE
              value: "provider-b"
          envFrom:
            - type: configMap
              configName: platform-config
            - type: configMap
              configName: platform-config-provider-b
          secretRefs:
            - shared-secrets
      serviceMonitor:
        endpoints:
          - port: http
            path: /api/provider-b/metrics

    # Core Service - No auto-creation, custom ingress
    core-service:
      autoCreateService: true
      autoCreateIngress: false  # Custom ingress configuration
      autoCreateServiceMonitor: true
      replicas: 1
      containers:
        main:
          image: "{{ $.Values.werf.repo }}"
          imageTag: "{{ $.Values.werf.tag.coreService }}"
          args:
            - "core:start"
          ports:
            http:
              containerPort: 8080
              protocol: TCP
          probes:
            livenessProbe:
              httpGet:
                path: /core/health
                port: http
              initialDelaySeconds: 10
          resources:
            requests:
              memory: "4000Mi"
            limits:
              memory: "4000Mi"
          env:
            - name: PORT
              value: "8080"
            - name: SERVICE_NAME
              value: "core-service"
            - name: FETCH_ON_RELOAD
              value: "true"
          envFrom:
            - type: configMap
              configName: platform-config
          secretRefs:
            - shared-secrets
      serviceMonitor:
        endpoints:
          - port: http
            path: /core/metrics

    # Processing Service - With HPA and Anti-Affinity
    processing-service:
      autoCreateService: true
      autoCreateIngress: false
      autoCreateServiceMonitor: true
      autoCreatePdb: true
      pdbConfig:
        minAvailable: 25%
      containers:
        main:
          image: "{{ $.Values.werf.repo }}"
          imageTag: "{{ $.Values.werf.tag.processor }}"
          args:
            - "processor:start"
          ports:
            http:
              containerPort: 8080
              protocol: TCP
          probes:
            readinessProbe:
              httpGet:
                path: /processor/health
                port: http
              initialDelaySeconds: 15
              periodSeconds: 5
              failureThreshold: 2
          lifecycle:
            preStop:
              httpGet:
                path: /processor/shutdown
                port: http
          resources:
            requests:
              memory: "2000Mi"
              cpu: "1000m"
            limits:
              memory: "2000Mi"
          env:
            - name: PORT
              value: "8080"
            - name: SERVICE_NAME
              value: "processing-service"
            - name: MONITORING_DSN
              value: "https://monitoring.example.com/project/2"
          envFrom:
            - type: configMap
              configName: platform-config
          secretRefs:
            - shared-secrets
      serviceMonitor:
        endpoints:
          - port: http
            path: /processor/metrics
      # HPA Configuration
      hpa:
        minReplicas: 1
        maxReplicas: 4
        metrics:
          - type: Resource
            resource:
              name: cpu
              target:
                type: Utilization
                averageUtilization: 60
      # Anti-affinity to spread across nodes
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app.kubernetes.io/component
                    operator: In
                    values:
                      - processing-service
              topologyKey: "kubernetes.io/hostname"

    # Data Fetcher - Minimal auto-creation
    data-fetcher:
      autoCreateService: false      # No service needed
      autoCreateIngress: false      # No ingress needed
      autoCreateServiceMonitor: false  # No metrics
      autoCreatePdb: true
      pdbConfig:
        minAvailable: 25%
      containers:
        main:
          image: "{{ $.Values.werf.repo }}"
          imageTag: "{{ $.Values.werf.tag.fetcher }}"
          args:
            - "fetcher:start"
          ports:
            http:
              containerPort: 8700
              protocol: TCP
          probes:
            readinessProbe:
              httpGet:
                path: /fetcher/health
                port: http
              initialDelaySeconds: 15
              periodSeconds: 5
              failureThreshold: 2
          resources:
            requests:
              memory: "256Mi"
              cpu: "200m"
            limits:
              memory: "512Mi"
          env:
            - name: PORT
              value: "8700"
            - name: SERVICE_NAME
              value: "data-fetcher"
            - name: FETCH_ON_RELOAD
              value: "true"
          envFrom:
            - type: configMap
              configName: platform-config
          secretRefs:
            - shared-secrets
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app.kubernetes.io/component
                    operator: In
                    values:
                      - data-fetcher
              topologyKey: "kubernetes.io/hostname"

  # Standalone ingresses configuration
  ingresses:
    platform-api:
      hosts:
        - host: ""  # Uses global domain
          paths:
            - path: /api/health
              pathType: Exact
              service: processing-service
              portName: http
            - path: /api/v1
              pathType: Prefix
              service: processing-service
              portName: http
            - path: /core/health
              pathType: Exact
              service: core-service
              portName: http
```

## Example 2: Environment-Specific Overrides

### values-dev.yaml

```yaml
ks-universal:
  generic:
    ingressesGeneral:
      domain: dev-platform.example.com
      annotations:
        cert-manager.io/cluster-issuer: "letsencrypt-staging"
        kubernetes.io/ingress.class: nginx-dev
  
  configs:
    platform-config:
      data:
        LOG_LEVEL: "debug"
        DATABASE_HOST: "dev-database.example.com"
        REDIS_HOST: "dev-redis.example.com"
        REDIS_DATABASE: "0"
        MESSAGE_QUEUE_HOST: "dev-rabbitmq.example.com"
        NODE_ENV: "development"
        STORAGE_ACCESS_KEY: "dev-access-key"

  # Development-specific node affinity
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: environment
                operator: In
                values:
                  - "development"
```

### values-stage.yaml

```yaml
ks-universal:
  generic:
    ingressesGeneral:
      domain: stage-platform.example.com
      annotations:
        cert-manager.io/cluster-issuer: "letsencrypt-staging"
        kubernetes.io/ingress.class: nginx-stage
  
  configs:
    platform-config:
      data:
        LOG_LEVEL: "info"
        DATABASE_HOST: "stage-database.example.com"
        REDIS_HOST: "stage-redis.example.com"
        REDIS_DATABASE: "0"
        REDIS_TLS: "true"
        MESSAGE_QUEUE_HOST: "stage-rabbitmq.example.com"
        NODE_ENV: "staging"
        STORAGE_ACCESS_KEY: "stage-access-key"

  # Add debug ports for staging
  deployments:
    api-gateway-provider-a:
      containers:
        main:
          ports:
            debug:
              containerPort: 9229
              protocol: TCP
    
    api-gateway-provider-b:
      containers:
        main:
          ports:
            debug:
              containerPort: 9229
              protocol: TCP

  # Staging-specific node affinity
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: environment
                operator: In
                values:
                  - "staging"
```

## Example 3: Advanced Patterns

### Using Migrations

```yaml
ks-universal:
  deployments:
    api-service:
      replicas: 3
      # Database migrations before deployment
      migrations:
        enabled: true
        backoffLimit: 1
        args: ["migrate", "up"]
      containers:
        main:
          image: api-service
          imageTag: v1.2.0
          # ... rest of configuration
```

### Using Custom ServiceMonitor Configuration

```yaml
ks-universal:
  deployments:
    metrics-heavy-service:
      autoCreateServiceMonitor: true
      serviceMonitor:
        # Advanced ServiceMonitor configuration
        endpoints:
          - port: http-metrics
            path: /metrics
            interval: "15s"
            scrapeTimeout: "10s"
            relabelings:
              - sourceLabels: [__meta_kubernetes_pod_name]
                targetLabel: pod_name
            metricRelabelings:
              - sourceLabels: [__name__]
                regex: 'go_.*'
                action: drop
            honorLabels: true
            scheme: https
            tlsConfig:
              insecureSkipVerify: true
        labels:
          prometheus: "custom-prometheus"
        namespaceSelector:
          matchNames:
            - monitoring
```

### Using Global DexAuthenticator

```yaml
ks-universal:
  generic:
    dexAuthenticatorGeneral:
      enabled: true
      applicationDomain: auth.example.com
      applicationIngressClassName: nginx
      keepUsersLoggedInFor: "24h"
      allowedGroups:
        - platform-users
        - administrators
      autoCreateCertificate: true
      certificate:
        clusterIssuer: letsencrypt-prod

  deployments:
    secure-api:
      autoCreateIngress: true
      ingress:
        hosts:
          - subdomain: "secure-api"
            paths:
              - path: "/"
                pathType: "Prefix"
        # Enable authentication for this ingress
        dexAuthenticator:
          enabled: true
```

### Using PersistentVolumeClaims

```yaml
ks-universal:
  persistentVolumeClaims:
    shared-storage:
      accessModes:
        - ReadWriteMany
      storageClassName: "nfs"
      size: 100Gi
    
    app-data:
      accessModes:
        - ReadWriteOnce
      storageClassName: "fast-ssd"
      size: 50Gi

  deployments:
    data-processor:
      containers:
        main:
          volumeMounts:
            - name: shared-volume
              mountPath: /shared
            - name: app-volume
              mountPath: /data
      volumes:
        - name: shared-volume
          persistentVolumeClaim:
            claimName: shared-storage
        - name: app-volume
          persistentVolumeClaim:
            claimName: app-data
```

## Key Patterns and Best Practices

### 1. Shared Configuration Strategy
- Use common ConfigMaps for shared settings
- Create provider/environment-specific ConfigMaps for variations
- Use `secretRefs` for sensitive data that's shared across services

### 2. Service Discovery
- Use consistent naming for services
- Enable `autoCreateService` for internal communication
- Use ServiceMonitor for Prometheus integration

### 3. Resource Management
- Set appropriate resource requests/limits
- Use HPA for scalable services
- Configure PDB for high-availability services

### 4. Security
- Always set `securityContext` with non-root users
- Use proper RBAC with ServiceAccounts
- Enable TLS where possible

### 5. Observability
- Enable ServiceMonitor for all services that expose metrics
- Use consistent health check endpoints
- Configure proper probes (liveness, readiness, startup)

### 6. Deployment Strategy
- Use anti-affinity for critical services
- Configure appropriate node selectors
- Use environment-specific overrides for different stages

### 7. Auto-Creation Benefits
- Use `autoCreateService`, `autoCreateServiceMonitor`, `autoCreatePdb` to reduce boilerplate
- Let the chart handle standard configurations
- Override only when you need custom behavior

This live example demonstrates how a real microservices platform uses ks-universal chart effectively, showing patterns for configuration management, service discovery, monitoring, and environment-specific deployments. 