# Ingress Configuration

## Overview
The ks-universal chart provides comprehensive support for Kubernetes Ingress resources, allowing you to manage external access to services in your cluster.

## Structure
```yaml
ingresses:
  ingress-name:
    ingressClassName: nginx  # Optional
    annotations: {}          # Optional
    tls: []                 # Optional
    hosts:
      - host: example.com
        paths:
          - path: /
            pathType: Prefix
            port: 80        # Optional, defaults to http
```

## Configuration Parameters

### Basic Configuration
- `ingressClassName`: Specifies which ingress controller to use
- `annotations`: Ingress-specific annotations
- `tls`: TLS configuration for secure connections
- `hosts`: List of host rules

### Host Configuration
- `host`: Domain name
- `paths`: List of path rules
  - `path`: URL path
  - `pathType`: Path match type (Prefix, Exact, ImplementationSpecific)
  - `port`: Service port number or name

## Examples

### Basic Ingress
```yaml
ingresses:
  web-ingress:
    ingressClassName: nginx
    hosts:
      - host: example.com
        paths:
          - path: /
            pathType: Prefix
            port: http
```

### Multiple Paths
```yaml
ingresses:
  api-ingress:
    ingressClassName: nginx
    hosts:
      - host: api.example.com
        paths:
          - path: /v1
            pathType: Prefix
            port: 8080
          - path: /v2
            pathType: Prefix
            port: 8081
```

### TLS Configuration
```yaml
ingresses:
  secure-ingress:
    ingressClassName: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    tls:
      - secretName: example-tls
        hosts:
          - secure.example.com
    hosts:
      - host: secure.example.com
        paths:
          - path: /
            pathType: Prefix
```

### Multiple Hosts
```yaml
ingresses:
  multi-domain:
    ingressClassName: nginx
    tls:
      - secretName: example1-tls
        hosts:
          - example1.com
      - secretName: example2-tls
        hosts:
          - example2.com
    hosts:
      - host: example1.com
        paths:
          - path: /
            pathType: Prefix
      - host: example2.com
        paths:
          - path: /
            pathType: Prefix
```

### With Custom Annotations
```yaml
ingresses:
  annotated-ingress:
    ingressClassName: nginx
    annotations:
      kubernetes.io/ingress.class: nginx
      nginx.ingress.kubernetes.io/rewrite-target: /
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
    hosts:
      - host: app.example.com
        paths:
          - path: /
            pathType: Prefix
```

## Common Annotations

### NGINX Ingress Controller
```yaml
annotations:
  nginx.ingress.kubernetes.io/rewrite-target: /
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
  nginx.ingress.kubernetes.io/proxy-body-size: "50m"
  nginx.ingress.kubernetes.io/proxy-read-timeout: "30"
```

### SSL/TLS
```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-prod
  kubernetes.io/tls-acme: "true"
```

### Basic Authentication
```yaml
annotations:
  nginx.ingress.kubernetes.io/auth-type: basic
  nginx.ingress.kubernetes.io/auth-secret: basic-auth
  nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
```

## Path Types

### Prefix
Matches based on URL path prefix:
```yaml
paths:
  - path: /api
    pathType: Prefix    # Matches /api, /api/, /api/v1, etc.
```

### Exact
Matches the exact URL path:
```yaml
paths:
  - path: /healthz
    pathType: Exact    # Only matches /healthz exactly
```

### ImplementationSpecific
Leaves interpretation up to the IngressClass:
```yaml
paths:
  - path: /files/.*
    pathType: ImplementationSpecific    # Interpretation depends on Ingress controller
```

## Notes
- Ingress resource requires an Ingress Controller in your cluster
- TLS certificates must be managed separately (e.g., using cert-manager)
- Path types are case-sensitive
- Port can be specified by number or name (matching the service port name)
- Multiple hosts and paths can share the same TLS certificate

## See Also
- [Services Configuration](./services.md)
- [Deployments Configuration](./deployments.md)
