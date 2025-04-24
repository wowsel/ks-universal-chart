# 🤖 Auto-creation Features

This guide explains the automatic resource creation capabilities of the ks-universal chart.

## 📑 Table of Contents
- [Available Features](#available-features)
- [Service Auto-creation](#service-auto-creation)
- [Ingress Auto-creation](#ingress-auto-creation)
- [Certificate Auto-creation](#certificate-auto-creation)
- [ServiceMonitor Auto-creation](#servicemonitor-auto-creation)
- [PDB Auto-creation](#pdb-auto-creation)
- [ServiceAccount Auto-creation](#serviceaccount-auto-creation)
- [Soft Anti-Affinity Auto-creation](#soft-anti-affinity-auto-creation)
- [Best Practices](#best-practices)

## ✨ Available Auto-creation Features

| Feature | Flag | Description |
|---------|------|-------------|
| Service | `autoCreateService` | Creates Kubernetes Service |
| Ingress | `autoCreateIngress` | Creates Ingress resource |
| Certificate | `autoCreateCertificate` | Creates cert-manager Certificate |
| ServiceMonitor | `autoCreateServiceMonitor` | Creates Prometheus ServiceMonitor |
| PDB | `autoCreatePdb` | Creates PodDisruptionBudget |
| ServiceAccount | `autoCreateServiceAccount` | Creates ServiceAccount |
| SoftAntiAffinity | `autoCreateSoftAntiAffinity` | Creates pod anti-affinity rules |

## 🔌 Service Auto-creation

<details>
<summary>Basic Service Configuration</summary>

```yaml
deployments:
  my-app:
    autoCreateService: true
    containers:
      main:
        ports:
          http:
            containerPort: 8080
            servicePort: 80    # Optional, defaults to containerPort
          metrics:
            containerPort: 9090
```

### Features
- Automatic port mapping
- Optional service port configuration
- Supports multiple ports
- Default service type: ClusterIP
- Custom service type via `serviceType` field
</details>

<details>
<summary>Advanced Service Configuration</summary>

```yaml
deployments:
  my-app:
    autoCreateService: true
    serviceType: LoadBalancer    # Override service type
    containers:
      main:
        ports:
          http:
            containerPort: 8080
            servicePort: 80
            protocol: TCP      # Optional, defaults to TCP
      metrics:
        ports:
          prometheus:
            containerPort: 9090
            servicePort: 9090
```
</details>

## 🌐 Ingress Auto-creation

<details>
<summary>Basic Ingress Configuration</summary>

```yaml
deployments:
  my-app:
    autoCreateIngress: true
    autoCreateService: true  # Required for Ingress
    ingress:
      hosts:
        - host: myapp.example.com
          paths:
            - path: /
              pathType: Prefix
        - subdomain: api    # Will use domain from generic.ingressesGeneral
          paths:
            - path: /
              pathType: Prefix
```
</details>

<details>
<summary>Global Ingress Configuration</summary>

```yaml
generic:
  ingressesGeneral:
    domain: example.com
    ingressClassName: nginx
    annotations:
      nginx.ingress.kubernetes.io/proxy-body-size: "10m"
```
</details>

## 🔒 Certificate Auto-creation

<details>
<summary>Certificate Configuration</summary>

```yaml
deployments:
  my-app:
    autoCreateIngress: true      # Required for Certificate
    autoCreateCertificate: true
    certificate:
      clusterIssuer: letsencrypt-prod  # Optional, defaults to "letsencrypt"
```

### Requirements
- cert-manager installed in cluster
- Configured ClusterIssuer/Issuer
- Valid domain configuration
</details>

## 🔐 DexAuthenticator Auto-creation

<details>
<summary>DexAuthenticator Configuration</summary>

```yaml
# DexAuthenticator in standalone ingress
ingresses:
  ingress-with-dex:
    hosts:
      - host: app.example.com
        paths:
          - path: /
            pathType: Prefix
            service: app-service
    dexAuthenticator:
      enabled: true                                  # Enable DexAuthenticator for this ingress
      sendAuthorizationHeader: false                 # Optional: Send Authorization header to the application
      applicationIngressCertificateSecretName: tls   # Secret with SSL certificate
      applicationIngressClassName: nginx             # Ingress class name
      keepUsersLoggedInFor: "720h"                   # Optional: Session duration
      allowedGroups:                                 # Optional: Restrict access to specific groups
        - everyone
      whitelistSourceRanges:                         # Optional: Restrict access to specific IP ranges
        - 1.1.1.1/32
```

```yaml
# DexAuthenticator in deployment with auto-created ingress
deployments:
  app-with-dex:
    autoCreateIngress: true
    ingress:
      hosts:
        - host: deploy.example.com
          paths:
            - path: /
              pathType: Prefix
      dexAuthenticator:
        enabled: true
        sendAuthorizationHeader: true
        applicationIngressCertificateSecretName: ingress-tls
        keepUsersLoggedInFor: "48h"
        allowedGroups:
          - developers
```

```yaml
# Multiple domains with a single DexAuthenticator
deployments:
  multi-domain-app:
    autoCreateIngress: true
    ingress:
      hosts:
        - host: first.example.com
          paths:
            - path: /
        - host: second.example.com
          paths:
            - path: /
      dexAuthenticator:
        enabled: true
        applicationIngressCertificateSecretName: ingress-tls
        additionalApplications:
          - domain: additional-app.example.com
            ingressSecretName: ingress-tls
            ingressClassName: nginx
            signOutURL: "/logout"
```

### Features
- Automatic creation of DexAuthenticator resources for Ingress hosts
- Support for multiple host configurations
- Integration with global domain settings
- Standalone or auto-created ingress support
- IP whitelisting support
- Group restrictions support
- **Automatic addition of required annotations to Ingress resources:**
  ```yaml
  annotations:
    nginx.ingress.kubernetes.io/auth-signin: https://$host/dex-authenticator/sign_in
    nginx.ingress.kubernetes.io/auth-response-headers: X-Auth-Request-User,X-Auth-Request-Email
    nginx.ingress.kubernetes.io/auth-url: https://<dex-name>-dex-authenticator.<namespace>.svc.cluster.local/dex-authenticator/auth
  ```

### Requirements
- Deckhouse Kubernetes Platform with user-authn module enabled
- Valid Ingress configuration with host(s)
</details>

## 📊 ServiceMonitor Auto-creation

<details>
<summary>Basic ServiceMonitor Configuration</summary>

```yaml
deployments:
  my-app:
    autoCreateService: true          # Required for ServiceMonitor
    autoCreateServiceMonitor: true
    containers:
      main:
        ports:
          http-metrics:              # Special port name for metrics
            containerPort: 9090
```

### Port Selection Logic
1. Looks for port named "http-metrics"
2. Uses first available port if http-metrics not found
</details>

<details>
<summary>Advanced ServiceMonitor Configuration</summary>

```yaml
deployments:
  my-app:
    autoCreateServiceMonitor: true
    serviceMonitor:
      endpoints:
        - port: metrics
          interval: 15s
          path: /metrics
          scrapeTimeout: 10s
          # Relabeling configuration
          relabelings:
            - sourceLabels: [__meta_kubernetes_pod_label_app_kubernetes_io_component]
              targetLabel: component
          # Metric relabeling
          metricRelabelings:
            - sourceLabels: [__name__]
              regex: 'go_.*'
              action: drop
```
</details>

## 🛡️ PDB Auto-creation

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

### Notes
- Use with multiple replicas
- Choose either minAvailable or maxUnavailable
- Consider maintenance windows
</details>

## 👤 ServiceAccount Auto-creation

<details>
<summary>ServiceAccount Configuration</summary>

```yaml
deployments:
  my-app:
    autoCreateServiceAccount: true
    serviceAccountConfig:
      annotations:
        eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/my-role"
```
</details>

## 🎯 Soft Anti-Affinity Auto-creation

<details>
<summary>Soft Anti-Affinity Configuration</summary>

```yaml
deployments:
  my-app:
    autoCreateSoftAntiAffinity: true  # Spreads pods across nodes
```

### Generated Configuration
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            app.kubernetes.io/component: my-app
        topologyKey: kubernetes.io/hostname
```
</details>

## 💡 Tips and Best Practices

### Service and Ingress
- Always enable `autoCreateService` with `autoCreateIngress`
- Use `servicePort` when needed
- Configure global ingress settings

### Certificates
- Ensure cert-manager is installed
- Configure default ClusterIssuer
- Use with `autoCreateIngress`

### Monitoring
- Use standard port name "http-metrics"
- Configure global ServiceMonitor settings
- Consider resource impact

### High Availability
- Use PDB with multiple replicas
- Configure appropriate disruption budget
- Enable soft anti-affinity

## 🔍 Troubleshooting

<details>
<summary>Common Issues</summary>

1. **Service Not Created**
   - Check if ports are defined
   - Verify container port configuration
   - Check logs for validation errors

2. **Ingress Issues**
   - Verify autoCreateService is enabled
   - Check domain configuration
   - Validate ingress controller setup

3. **Certificate Problems**
   - Verify cert-manager installation
   - Check ClusterIssuer status
   - Review certificate logs

4. **ServiceMonitor Not Working**
   - Verify Prometheus operator installation
   - Check metric endpoint accessibility
   - Review port configurations
</details>

## 📝 Real-World Examples

<details>
<summary>Complete Application Stack</summary>

```yaml
deployments:
  backend:
    autoCreateService: true
    autoCreateIngress: true
    autoCreateCertificate: true
    autoCreateServiceMonitor: true
    autoCreatePdb: true
    autoCreateSoftAntiAffinity: true
    containers:
      main:
        image: backend
        imageTag: v1.0.0
        ports:
          http:
            containerPort: 8080
          metrics:
            containerPort: 9090
    ingress:
      hosts:
        - host: api.example.com
          paths:
            - path: /
              pathType: Prefix
    pdbConfig:
      minAvailable: 2
```
</details>