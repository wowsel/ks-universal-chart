# Monitoring with ks-universal

This document provides a detailed overview of the monitoring capabilities in the ks-universal Helm chart.

## Table of Contents
- [Overview](#overview)
- [Configuration Options](#configuration-options)
- [Use Cases](#use-cases)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

The ks-universal chart provides comprehensive monitoring support through Prometheus ServiceMonitors. Key features include:
- Automatic ServiceMonitor creation
- Multi-container monitoring
- Custom metric endpoints
- Flexible scraping configurations
- Integration with Prometheus Operator

## Configuration Options

### Global Settings

```yaml
generic:
  serviceMonitorGeneral:
    labels:
      prometheus: kube-prometheus
    interval: 30s
    scrapeTimeout: 10s
```

### Per-Deployment Settings

Basic configuration:
```yaml
deployments:
  my-app:
    autoCreateServiceMonitor: true
    serviceMonitor:
      path: /metrics
      interval: 15s
```

Advanced configuration:
```yaml
serviceMonitor:
  endpoints:
    - port: metrics
      interval: 15s
      path: /metrics
      scrapeTimeout: 10s
      relabelings:
        - sourceLabels: [__meta_kubernetes_pod_label_app_kubernetes_io_component]
          targetLabel: component
      metricRelabelings:
        - sourceLabels: [__name__]
          regex: 'go_.*'
          action: drop
```

## Use Cases

### Standard Web Application
Best for typical web applications with basic metrics:
```yaml
deployments:
  web-app:
    autoCreateServiceMonitor: true
    containers:
      main:
        ports:
          http-metrics:
            containerPort: 9090
```

### High-Performance Application
For applications requiring fine-tuned monitoring:
```yaml
serviceMonitor:
  endpoints:
    - port: metrics
      interval: 10s
      path: /metrics/basic
    - port: metrics
      interval: 30s
      path: /metrics/detailed
```

### Database Monitoring
For monitoring databases with exporters:
```yaml
containers:
  db:
    image: postgres
    ports:
      postgres:
        containerPort: 5432
  exporter:
    image: postgres-exporter
    ports:
      http-metrics:
        containerPort: 9187
serviceMonitor:
  endpoints:
    - port: http-metrics
      interval: 20s
```

## Best Practices

1. **Port Naming Conventions**
   - Use `http-metrics` for automatic discovery
   - Use descriptive names for additional ports

2. **Resource Considerations**
   - Adjust intervals based on resource usage
   - Use longer intervals for resource-intensive metrics
   - Consider scrapeTimeout for slow metrics

3. **Label Management**
   - Use consistent labeling schemes
   - Leverage relabeling for better organization
   - Keep cardinality under control

4. **Multi-Container Setup**
   - Separate concerns between containers
   - Use dedicated exporters when needed
   - Configure appropriate intervals per container

## Troubleshooting

### Common Issues

1. **ServiceMonitor Not Found**
   - Check labels match Prometheus Operator configuration
   - Verify serviceMonitor CRD is installed

2. **Metrics Not Scraped**
   - Verify port names match ServiceMonitor configuration
   - Check endpoint accessibility
   - Validate metrics path

3. **High Resource Usage**
   - Adjust scraping intervals
   - Review metric cardinality
   - Consider using metricRelabelings to drop unnecessary metrics

### Debugging Steps

1. Check ServiceMonitor creation:
```bash
kubectl get servicemonitor -n your-namespace
```

2. Verify endpoint discovery:
```bash
kubectl get endpoints -n your-namespace
```

3. Test metrics endpoint:
```bash
kubectl port-forward svc/your-service 9090:9090
curl localhost:9090/metrics
```

### Performance Optimization

1. **Interval Tuning**
```yaml
serviceMonitor:
  endpoints:
    - port: metrics
      interval: 30s  # Increase for less critical metrics
    - port: metrics-detailed
      interval: 60s  # Longer interval for resource-intensive metrics
```

2. **Metric Filtering**
```yaml
metricRelabelings:
  - sourceLabels: [__name__]
    regex: 'go_gc_.*'
    action: keep  # Only keep relevant metrics
```

3. **Resource Limits**
```yaml
containers:
  exporter:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
```

## Integration Examples

### Grafana Dashboard Integration
```yaml
podAnnotations:
  grafana-dashboard: "true"
```

### Alert Manager Integration
```yaml
serviceMonitor:
  endpoints:
    - port: metrics
      interval: 15s
      metricRelabelings:
        - sourceLabels: [__name__]
          regex: 'error_.*'
          action: keep
```

These configurations and examples should help you effectively monitor your applications using the ks-universal chart. For specific use cases or additional configuration options, refer to the main documentation or create an issue on GitHub.