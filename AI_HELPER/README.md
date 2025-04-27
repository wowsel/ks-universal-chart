# KS Universal Chart: AI Agent Documentation

This documentation is designed specifically for AI agents (Claude, Gemini, ChatGPT, etc.) to understand and work with the ks-universal Helm chart. It contains detailed information about the chart's structure, templates, functionality, and capabilities.

## Chart Overview

The ks-universal chart is a highly flexible, universal Helm chart designed to deploy various Kubernetes resources with a unified configuration approach. The chart supports:

- Deployments
- Services
- Ingress resources
- CronJobs
- Jobs
- DexAuthenticator
- ServiceMonitors (for Prometheus)
- PodDisruptionBudgets (PDB)
- PersistentVolumeClaims (PVC)
- HorizontalPodAutoscalers (HPA)
- Certificates (cert-manager)
- ConfigMaps

## Directory Structure

```
charts/ks-universal/
├── templates/
│   ├── _helpers.tpl       # Helper functions for templates
│   ├── _validation.tpl    # Validation functions
│   ├── certificate.yaml   # Certificate template
│   ├── configs.yaml       # ConfigMaps template
│   ├── cronjob.yaml       # CronJob template
│   ├── deployment.yaml    # Deployment template
│   ├── dexauthenticator.yaml # DexAuthenticator template
│   ├── hpa.yaml           # HorizontalPodAutoscaler template
│   ├── ingress.yaml       # Ingress template
│   ├── job.yaml           # Job template
│   ├── NOTES.txt          # Installation notes
│   ├── pdb.yaml           # PodDisruptionBudget template
│   ├── pvc.yaml           # PersistentVolumeClaim template
│   ├── service.yaml       # Service template
│   ├── serviceaccount.yaml # ServiceAccount template
│   └── servicemonitor.yaml # ServiceMonitor template
```

## Core Concepts

### 1. Helper Functions

The chart relies on a comprehensive set of helper functions defined in `_helpers.tpl`:

- **Name Helpers**:
  - `ks-universal.name`: Expands the chart name
  - `ks-universal.fullname`: Creates the full name of resources

- **Label Helpers**:
  - `ks-universal.labels`: Common labels for resources
  - `ks-universal.selectorLabels`: Selector labels for resources
  - `ks-universal.componentLabels`: Component-specific labels
  - `ks-universal.deploymentSelector`: Deployment selector labels

- **Resource Generation Helpers**:
  - `ks-universal.deploymentDefaults`: Applies default values to deployments
  - `ks-universal.ingressDefaults`: Applies default values to ingress resources
  - `ks-universal.containers`: Generates container specifications
  - `ks-universal.autoIngress`: Generates automatic ingress resources
  - `ks-universal.autoPdb`: Generates automatic PodDisruptionBudgets
  - `ks-universal.serviceMonitor`: Generates ServiceMonitor resources
  - `ks-universal.autoCertificate`: Generates automatic certificates

- **Utility Helpers**:
  - `ks-universal.processAffinity`: Processes affinity settings
  - `ks-universal.tplValue`: Processes dynamic template values
  - `ks-universal.processSecretRefs`: Processes secret references

### 2. Validation Functions

The chart includes extensive validation logic in `_validation.tpl`:

- **General Validation**:
  - `ks-universal.validateNotNil`: Checks that values are not nil
  - `ks-universal.validateRequired`: Checks required fields
  - `ks-universal.validateRange`: Validates numeric ranges

- **Resource-Specific Validation**:
  - `ks-universal.validateContainer`: Validates container configuration
  - `ks-universal.validatePorts`: Validates port configuration
  - `ks-universal.validateHPA`: Validates HorizontalPodAutoscaler configuration
  - `ks-universal.validatePDB`: Validates PodDisruptionBudget configuration
  - `ks-universal.validateServiceMonitor`: Validates ServiceMonitor configuration
  - `ks-universal.validateSecretRefs`: Validates secret references

## Configuration Structure

### Values File Structure

The chart uses a hierarchical values structure that allows for both global and resource-specific configuration:

```yaml
# Global settings
generic:
  # General settings for all deployments
  deploymentsGeneral:
    securityContext: {}
    nodeSelector: {}
    tolerations: []
    affinity: {}
    probes: {}
    strategy: {}
  
  # General settings for all ingress resources
  ingressesGeneral:
    annotations: {}
    ingressClassName: "nginx"
    domain: "example.com"  # Global domain for all ingresses
    tls: []
  
  # General settings for service monitors
  serviceMonitorGeneral:
    interval: "30s"
    scrapeTimeout: "10s"
    labels: {}
  
  # General settings for DexAuthenticator
  dexAuthenticatorGeneral:
    namespace: "default"
    name: "dex"
  
  # Extra pull secrets
  extraImagePullSecrets: []

# Secret references that can be included in containers
secretRefs:
  database:
    - name: DB_HOST
      secretKeyRef:
        name: db-credentials
        key: host
    - name: DB_PASSWORD
      secretKeyRef:
        name: db-credentials
        key: password

# Deployments
deployments:
  app-name:
    replicas: 1
    containers:
      app:
        image: "nginx"
        imageTag: "latest"
        ports:
          http:
            containerPort: 80
        resources: {}
        probes: {}
    autoCreateService: true
    autoCreateIngress: true
    autoCreatePdb: true
    autoCreateServiceMonitor: true
    autoCreateServiceAccount: true
    autoCreateCertificate: true
    ingress:
      hosts:
        - subdomain: "app"  # Will become app.example.com if generic.ingressesGeneral.domain is set
          paths:
            - path: "/"
              pathType: "Prefix"

# Services
services:
  custom-service:
    type: ClusterIP
    ports:
      - name: http
        port: 80
        targetPort: 8080

# CronJobs
cronJobs:
  backup:
    schedule: "0 2 * * *"
    containers:
      backup:
        image: "backup-tool"
        imageTag: "1.0.0"
        command: ["/bin/sh", "-c", "backup.sh"]

# Jobs
jobs:
  migration:
    containers:
      migration:
        image: "migration-tool"
        imageTag: "1.0.0"
        command: ["/bin/sh", "-c", "migrate.sh"]

# ConfigMaps
configs:
  app-config:
    data:
      config.json: |
        {
          "key": "value"
        }
```

## Key Features

### 1. Auto-creation of Resources

The chart can automatically create related resources for deployments:

- `autoCreateService`: Creates a Service for the deployment
- `autoCreateIngress`: Creates an Ingress resource
- `autoCreatePdb`: Creates a PodDisruptionBudget
- `autoCreateServiceMonitor`: Creates a ServiceMonitor for Prometheus
- `autoCreateServiceAccount`: Creates a ServiceAccount
- `autoCreateCertificate`: Creates a cert-manager Certificate

### 2. Inheritance from Global Settings

Resource configurations can inherit settings from global configurations:

- Deployments inherit from `generic.deploymentsGeneral`
- Ingress resources inherit from `generic.ingressesGeneral`
- ServiceMonitors inherit from `generic.serviceMonitorGeneral`

### 3. Automatic Domain Handling

The chart supports automatic domain construction:

- If `generic.ingressesGeneral.domain` is set (e.g., "example.com")
- And an ingress host has a `subdomain` (e.g., "app")
- Then the full domain will be constructed as "app.example.com"

### 4. Secret References

The chart allows defining secret references centrally and using them in containers:

```yaml
secretRefs:
  database:
    - name: DB_HOST
      secretKeyRef:
        name: db-credentials
        key: host

deployments:
  app:
    containers:
      app:
        secretRefs:
          - database  # This will include all environment variables from the database secretRef
```

### 5. Affinity Handling

The chart provides sophisticated affinity handling:

- `autoCreateSoftAntiAffinity`: Automatically creates pod anti-affinity rules
- `processAffinity`: Converts nodeSelector settings into nodeAffinity

## Template Logic Flow

For AI agents, understanding the template logic flow is crucial:

1. **Validation**: Templates first validate the provided values
2. **Default Application**: Default values are applied from global settings
3. **Resource Generation**: Resources are generated based on the configuration
4. **Auto-creation**: Additional resources are auto-created if enabled

## Common Pattern Examples

### Deploying a Web Application

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
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "100m"
            memory: "128Mi"
        probes:
          livenessProbe:
            httpGet:
              path: /healthz
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
    autoCreateService: true
    autoCreateIngress: true
    ingress:
      hosts:
        - subdomain: "web"
          paths:
            - path: "/"
              pathType: "Prefix"
```

### Creating a Microservice with Database

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

### Setting Up a Scheduled Job

```yaml
cronJobs:
  backup-job:
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
```

## Testing and Development Guidelines

### Testing Values

When developing tests for this chart, use the following approaches:

1. **Minimal Values**: Test with minimal required configuration
2. **Full Configuration**: Test with all possible options
3. **Edge Cases**: Test with boundary values
4. **Invalid Configuration**: Test validation by providing invalid values

### Testing Location

Tests are located in:
- `charts/ks-universal/tests/values/`: Test values files
- `charts/ks-universal/tests/`: Test scripts

### CI/CD Integration

The chart includes GitHub workflow configurations for:
- Chart linting
- Template validation
- Release management

## Advanced Usage

### Using Templates in Values

The chart supports templating in values:

```yaml
deployments:
  app:
    containers:
      app:
        image: "{{ .Release.Name }}-image"
        imageTag: "{{ .Chart.AppVersion }}"
```

### Multiple Container Deployments

```yaml
deployments:
  app:
    containers:
      app:
        image: "app"
        imageTag: "v1"
        ports:
          http:
            containerPort: 8080
      sidecar:
        image: "sidecar"
        imageTag: "v1"
        ports:
          metrics:
            containerPort: 9090
```

## Common Patterns and Best Practices

1. **Use Auto-creation Features**: Leverage auto-creation for related resources
2. **Define Global Settings**: Set common configurations in the generic section
3. **Use Secret References**: Centralize secret configurations
4. **Structured Naming Convention**: Follow a consistent naming convention for resources
5. **Validation First**: Always validate inputs before processing

## Troubleshooting Guide for AI Agents

When encountering issues with the chart, follow these steps:

1. **Check Validation Errors**: Look for validation failures that indicate configuration issues
2. **Trace Template Flow**: Follow the template logic flow to identify where errors occur
3. **Examine Generated Resources**: Review the generated Kubernetes manifests
4. **Check Inheritance**: Verify that global settings are being properly inherited

## Resource Generation Logic

Here's the detailed logic for how resources are generated:

1. **Deployments**:
   - Basic deployment configuration is merged with global defaults
   - Labels and selectors are automatically generated
   - Container specifications are processed

2. **Services**:
   - Can be created explicitly or auto-generated from deployments
   - Service ports are derived from container ports
   - Selectors are automatically matched to deployments

3. **Ingress**:
   - Can inherit global annotations and TLS configuration
   - Supports domain construction with subdomain and global domain
   - Paths are configured per host

4. **ServiceMonitors**:
   - Can target specific metrics ports or default to first available port
   - Supports detailed endpoint configuration
   - Can inherit global scrape intervals and timeouts

## Relationship Between Resources

Understanding the relationships between resources is crucial:

- **Deployment → Service**: Services target deployments using selector labels
- **Service → Ingress**: Ingress routes traffic to services based on host/path rules
- **Deployment → ServiceMonitor**: ServiceMonitors target deployment metrics through services
- **Deployment → PDB**: PDBs protect deployments from disruption during updates
- **Ingress → Certificate**: Certificates are created for domains used in ingress resources 