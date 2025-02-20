# Auto-creation Features

This guide explains the automatic resource creation capabilities of the ks-universal chart.

## Available Auto-creation Features

- `autoCreateService`
- `autoCreateIngress`
- `autoCreateCertificate`
- `autoCreateServiceMonitor`
- `autoCreatePdb`
- `autoCreateServiceAccount`
- `autoCreateSoftAntiAffinity`

## Service Auto-creation

The `autoCreateService` feature automatically creates a Kubernetes Service based on container port definitions.

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

## Ingress Auto-creation

The `autoCreateIngress` feature creates an Ingress resource with SSL support.

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

### Global Ingress Configuration
```yaml
generic:
  ingressesGeneral:
    domain: example.com
    ingressClassName: nginx
    annotations:
      nginx.ingress.kubernetes.io/proxy-body-size: "10m"
```

## Certificate Auto-creation

The `autoCreateCertificate` feature integrates with cert-manager for SSL/TLS certificates.

```yaml
deployments:
  my-app:
    autoCreateIngress: true      # Required for Certificate
    autoCreateCertificate: true
    certificate:
      clusterIssuer: letsencrypt-prod  # Optional, defaults to "letsencrypt"
```

## ServiceMonitor Auto-creation

The `autoCreateServiceMonitor` feature creates Prometheus ServiceMonitor resources.

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

## PDB Auto-creation

The `autoCreatePdb` feature creates PodDisruptionBudget for high availability.

```yaml
deployments:
  my-app:
    autoCreatePdb: true
    pdbConfig:
      minAvailable: 1
      # or
      maxUnavailable: 1
```

## ServiceAccount Auto-creation

The `autoCreateServiceAccount` feature creates a dedicated ServiceAccount.

```yaml
deployments:
  my-app:
    autoCreateServiceAccount: true
    serviceAccountConfig:
      annotations:
        eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/my-role"
```

## Soft Anti-Affinity

The `autoCreateSoftAntiAffinity` feature adds pod anti-affinity rules.

```yaml
deployments:
  my-app:
    autoCreateSoftAntiAffinity: true  # Spreads pods across nodes
```

## Tips and Best Practices

1. **Service and Ingress**
   - Always enable `autoCreateService` with `autoCreateIngress`
   - Use `servicePort` when needed
   - Configure global ingress settings

2. **Certificates**
   - Ensure cert-manager is installed
   - Configure default ClusterIssuer
   - Use with `autoCreateIngress`

3. **Monitoring**
   - Use standard port name "http-metrics"
   - Configure global ServiceMonitor settings
   - Consider resource impact

4. **High Availability**
   - Use PDB with multiple replicas
   - Configure appropriate disruption budget
   - Enable soft anti-affinity