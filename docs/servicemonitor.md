# ServiceMonitor Configuration

## Overview
ServiceMonitor resources are used with the Prometheus Operator to automatically discover and scrape metrics from your services.

## Structure
```yaml
deployments:
  deployment-name:
    autoCreateServiceMonitor: true
    serviceMonitor:
      labels: {}    # Additional labels for ServiceMonitor
    containers:
      container-name:
        ports:
          http-metrics:
            containerPort: 9090
```

## Configuration Parameters

### Basic Configuration
- `autoCreateServiceMonitor`: Enable automatic ServiceMonitor creation
- `serviceMonitor.labels`: Additional labels for ServiceMonitor resource

### Requirements
- Container must expose metrics on port named `http-metrics`
- Prometheus Operator must be installed in the cluster

## Examples

### Basic Metrics Monitoring
```yaml
deployments:
  web-app:
    autoCreateServiceMonitor: true
    containers:
      app:
        ports:
          http-metrics:
            containerPort: 9090
```

### With Custom Labels
```yaml
deployments:
  backend:
    autoCreateServiceMonitor: true
    serviceMonitor:
      labels:
        release: prometheus
    containers:
      app:
        ports:
          http-metrics:
            containerPort: 8080
```

### Complete Application Monitoring
```yaml
deployments:
  full-stack-app:
    autoCreateServiceMonitor: true
    serviceMonitor:
      labels:
        prometheus: default
        environment: production
    containers:
      app:
        image: my-app
        imageTag: v1.0.0
        ports:
          http:
            containerPort: 8080
          http-metrics:
            containerPort: 9090
        probes:
          livenessProbe:
            httpGet:
              path: /health
              port: http
          readinessProbe:
            httpGet:
              path: /ready
              port: http
```

### Multiple Services Monitoring
```yaml
deployments:
  auth-service:
    autoCreateServiceMonitor: true
    containers:
      auth:
        ports:
          http-metrics:
            containerPort: 9090
  
  payment-service:
    autoCreateServiceMonitor: true
    containers:
      payment:
        ports:
          http-metrics:
            containerPort: 9090
```

## Common Metric Endpoints

### Spring Boot Applications
```yaml
deployments:
  spring-app:
    autoCreateServiceMonitor: true
    containers:
      app:
        ports:
          http-metrics:
            containerPort: 8080
        env:
          - name: MANAGEMENT_SERVER_PORT
            value: "8080"
          - name: MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE
            value: "prometheus,health,info,metrics"
```

### Node.js Applications
```yaml
deployments:
  node-app:
    autoCreateServiceMonitor: true
    containers:
      app:
        ports:
          http-metrics:
            containerPort: 9090
```

### Custom Metrics
```yaml
deployments:
  custom-app:
    autoCreateServiceMonitor: true
    serviceMonitor:
      labels:
        custom-metrics: "true"
    containers:
      app:
        ports:
          http-metrics:
            containerPort: 9090
```

## Best Practices

1. Port Configuration
   - Use consistent port names (`http-metrics`)
   - Consider standard port numbers (9090 for Prometheus)
   - Document metric endpoints

2. Labels
   - Use meaningful label selectors
   - Consider monitoring environment
   - Maintain consistent labeling scheme

3. Security
   - Consider metrics endpoint security
   - Use appropriate RBAC settings
   - Control access to sensitive metrics

4. Resource Management
   - Set appropriate scrape intervals
   - Consider metrics cardinality
   - Monitor resource usage

## Integration Patterns

### With HPA
```yaml
deployments:
  scalable-app:
    autoCreateServiceMonitor: true
    containers:
      app:
        ports:
          http-metrics:
            containerPort: 9090
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

### With Service Configuration
```yaml
deployments:
  monitored-service:
    autoCreateServiceMonitor: true
    autoCreateService: true
    serviceType: ClusterIP
    containers:
      app:
        ports:
          http:
            containerPort: 8080
          http-metrics:
            containerPort: 9090
```

## Notes
- ServiceMonitor requires Prometheus Operator
- Metrics endpoint must be HTTP/HTTPS
- Consider rate limiting for metric scraping
- Monitor metric cardinality
- Plan for metric retention

## See Also
- [Deployments Configuration](./deployments.md)
- [Services Configuration](./services.md)
