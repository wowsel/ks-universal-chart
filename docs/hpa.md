# HPA (Horizontal Pod Autoscaler) Configuration

## Overview
The ks-universal chart supports Horizontal Pod Autoscaler (HPA) configuration for automatic scaling of deployments based on various metrics.

## Structure
```yaml
deployments:
  deployment-name:
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
      behavior:
        scaleUp: {}
        scaleDown: {}
```

## Configuration Parameters

### Basic Configuration
- `minReplicas`: Minimum number of replicas
- `maxReplicas`: Maximum number of replicas
- `metrics`: List of metrics to use for scaling
- `behavior`: Optional scaling behavior configuration

### Metrics Types
1. Resource Metrics
2. Pods Metrics
3. Object Metrics
4. External Metrics

## Examples

### CPU-Based Scaling
```yaml
deployments:
  api:
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

### Memory-Based Scaling
```yaml
deployments:
  web:
    hpa:
      minReplicas: 1
      maxReplicas: 5
      metrics:
        - type: Resource
          resource:
            name: memory
            target:
              type: Utilization
              averageUtilization: 75
```

### Multiple Metrics
```yaml
deployments:
  backend:
    hpa:
      minReplicas: 2
      maxReplicas: 8
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
              averageUtilization: 85
```

### Custom Metrics
```yaml
deployments:
  queue-processor:
    hpa:
      minReplicas: 1
      maxReplicas: 10
      metrics:
        - type: Pods
          pods:
            metric:
              name: queue_length
            target:
              type: AverageValue
              averageValue: 100
```

### Scaling Behavior
```yaml
deployments:
  api:
    hpa:
      minReplicas: 2
      maxReplicas: 10
      metrics:
        - type: Resource
          resource:
            name: cpu
            target:
              type: Utilization
              averageUtilization: 75
      behavior:
        scaleUp:
          stabilizationWindowSeconds: 60
          policies:
            - type: Pods
              value: 2
              periodSeconds: 60
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
            - type: Pods
              value: 1
              periodSeconds: 120
```

## Metric Types Details

### Resource Metrics
```yaml
metrics:
  - type: Resource
    resource:
      name: cpu  # or memory
      target:
        type: Utilization  # or AverageValue
        averageUtilization: 80
```

### Pods Metrics
```yaml
metrics:
  - type: Pods
    pods:
      metric:
        name: packets-per-second
      target:
        type: AverageValue
        averageValue: 1k
```

### Object Metrics
```yaml
metrics:
  - type: Object
    object:
      metric:
        name: requests-per-second
      describedObject:
        apiVersion: networking.k8s.io/v1
        kind: Ingress
        name: main-route
      target:
        type: Value
        value: 10k
```

### External Metrics
```yaml
metrics:
  - type: External
    external:
      metric:
        name: queue_messages_ready
        selector:
          matchLabels:
            queue: "worker_tasks"
      target:
        type: AverageValue
        averageValue: 30
```

## Best Practices

1. Resource-Based Scaling
   - Start with CPU-based scaling
   - Use memory scaling carefully
   - Set appropriate target utilization (usually 50-80%)

2. Scaling Behavior
   - Use stabilization windows to prevent flapping
   - Configure scale-down policies more conservatively
   - Scale up can be more aggressive

3. Metrics Selection
   - Choose metrics relevant to application performance
   - Consider multiple metrics for better scaling decisions
   - Validate custom metrics availability

## Notes
- HPA requires metrics server for resource metrics
- Custom metrics require additional setup (e.g., Prometheus Adapter)
- Scaling is disabled if deployment has replicas explicitly set
- Target utilization should be based on application characteristics
- Consider resource requests/limits when configuring HPA

## See Also
- [Deployments Configuration](./deployments.md)
- [ServiceMonitor Configuration](./servicemonitor.md)
