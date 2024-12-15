# Services Configuration

## Overview
The ks-universal chart provides two ways to create Kubernetes Services:
1. Automatic service creation based on deployment configuration
2. Explicit service definition in the `services` section

## Automatic Service Creation

Services can be automatically created for deployments by setting `autoCreateService: true` in the deployment configuration.

```yaml
deployments:
  web-app:
    autoCreateService: true
    serviceType: ClusterIP  # Optional, defaults to ClusterIP
    containers:
      nginx:
        ports:
          http:
            containerPort: 80
            protocol: TCP   # Optional, defaults to TCP
```

The service will be created with:
- Name matching the deployment name
- Ports configured from the container ports
- Selectors matching the deployment labels

## Manual Service Configuration

For more control over service configuration, you can define services explicitly in the `services` section:

```yaml
services:
  service-name:
    type: ClusterIP        # Optional, defaults to ClusterIP
    ports:
      - name: http
        port: 80
        targetPort: 8080
        protocol: TCP      # Optional, defaults to TCP
```

### Supported Service Types
- ClusterIP (default)
- NodePort
- LoadBalancer
- ExternalName

## Port Configuration

### Port Fields
- `name`: Port name (required)
- `port`: Service port number (required)
- `targetPort`: Pod port number (required)
- `protocol`: Protocol (optional, defaults to TCP)

### Multiple Ports
Services can expose multiple ports:

```yaml
services:
  web-service:
    ports:
      - name: http
        port: 80
        targetPort: 8080
      - name: https
        port: 443
        targetPort: 8443
```

## Examples

### Basic Web Service
```yaml
services:
  web:
    type: ClusterIP
    ports:
      - name: http
        port: 80
        targetPort: 8080
```

### LoadBalancer Service
```yaml
services:
  api-gateway:
    type: LoadBalancer
    ports:
      - name: http
        port: 80
        targetPort: 8080
      - name: https
        port: 443
        targetPort: 8443
```

### Dual Service Configuration
Sometimes you might want both internal and external services for the same deployment:

```yaml
services:
  app-internal:
    type: ClusterIP
    ports:
      - name: http
        port: 80
        targetPort: 8080
  
  app-external:
    type: LoadBalancer
    ports:
      - name: http
        port: 80
        targetPort: 8080
```

### Service with NodePort
```yaml
services:
  monitoring:
    type: NodePort
    ports:
      - name: metrics
        port: 9090
        targetPort: 9090
        nodePort: 30090
```

## Auto-Created vs Explicit Services

### When to Use Auto-Created Services
- Simple applications with standard port configurations
- When service name should match deployment name
- When all container ports should be exposed

### When to Use Explicit Services
- Custom service types required
- Different port mapping needed
- Multiple services for one deployment
- Special service configurations

## Notes
- Service names must be unique within a namespace
- Port names must be unique within a service
- When using auto-created services, the service name will match the deployment name
- Port numbers must be between 1 and 65535
- NodePort values must be between 30000-32767 when specified

## See Also
- [Deployments Configuration](./deployments.md)
- [Ingress Configuration](./ingress.md)
