# Troubleshooting Guide

## Common Issues and Solutions

### Deployment Issues

#### Pods Not Starting
1. Check pod status:
```bash
kubectl get pods -l app.kubernetes.io/instance=<release-name>
```

2. Check pod events:
```bash
kubectl describe pod <pod-name>
```

Common causes:
- Image pull errors
- Resource constraints
- Node selector/affinity rules not matching
- Volume mount issues

Solutions:
- Verify image name and tag
- Check resource requests and limits
- Verify node labels
- Check PVC status

#### Container Crashes

1. Check container logs:
```bash
kubectl logs <pod-name> -c <container-name>
```

2. Check previous container logs:
```bash
kubectl logs <pod-name> -c <container-name> --previous
```

Common causes:
- Application errors
- Configuration issues
- Memory limits
- Liveness probe failures

Solutions:
- Review application logs
- Verify environment variables
- Adjust memory limits
- Check probe configurations

### Service Issues

#### Service Not Accessible

1. Check service status:
```bash
kubectl get svc <service-name>
```

2. Verify endpoints:
```bash
kubectl get endpoints <service-name>
```

Common causes:
- Label selector mismatch
- Port configuration errors
- Pod not ready

Solutions:
- Verify service selector labels
- Check port mappings
- Verify readiness probe

### Ingress Issues

#### Traffic Not Reaching Service

1. Check ingress status:
```bash
kubectl get ingress <ingress-name>
```

2. Verify TLS configuration:
```bash
kubectl get secret <tls-secret-name>
```

Common causes:
- Incorrect path configuration
- TLS certificate issues
- Ingress controller not configured
- Backend service issues

Solutions:
- Verify path and host configuration
- Check TLS certificate status
- Verify ingress controller setup
- Test backend service directly

### Configuration Issues

#### ConfigMap/Secret Not Mounted

1. Check volume mounts:
```bash
kubectl describe pod <pod-name>
```

2. Verify config existence:
```bash
kubectl get configmap,secret
```

Common causes:
- Missing configuration
- Incorrect name references
- Mount path issues

Solutions:
- Verify config names
- Check volume mount paths
- Review deployment configuration

### HPA Issues

#### Not Scaling

1. Check HPA status:
```bash
kubectl get hpa <hpa-name>
```

2. Check metrics:
```bash
kubectl describe hpa <hpa-name>
```

Common causes:
- Metrics not available
- Resource limits not set
- Target utilization issues

Solutions:
- Verify metrics-server installation
- Set resource requests/limits
- Adjust target utilization

## Validation Commands

### Chart Validation
```bash
# Validate chart syntax
helm lint .

# Test chart rendering
helm template <release-name> .

# Verify values
helm get values <release-name>
```

### Resource Validation
```bash
# Check all resources
kubectl get all -l app.kubernetes.io/instance=<release-name>

# Check specific resource types
kubectl get deploy,svc,ing,cm,secret -l app.kubernetes.io/instance=<release-name>
```

## Debug Tools

### Temporary Debug Container
```yaml
# Add to deployment container spec
containers:
  debug:
    image: busybox
    command: ['sleep', '3600']
```

### Network Debug
```bash
# Test service connectivity
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash
```

## Logging and Monitoring

### Accessing Logs
```bash
# Get application logs
kubectl logs -l app.kubernetes.io/instance=<release-name>

# Get specific container logs
kubectl logs <pod-name> -c <container-name>

# Follow logs
kubectl logs -f <pod-name>
```

### Monitoring Metrics
```bash
# Access metrics endpoint
kubectl port-forward svc/<service-name> 9090:9090

# Check ServiceMonitor
kubectl get servicemonitor <name>
```

## Common Helm Commands

### Installation and Upgrade
```bash
# Debug installation
helm install <release-name> . --dry-run --debug

# Force resource updates
helm upgrade <release-name> . --force

# Rollback to previous version
helm rollback <release-name> <revision>
```

## Best Practices for Troubleshooting

1. Systematic Approach
   - Start with pod status
   - Check events
   - Review logs
   - Verify configurations

2. Configuration Validation
   - Use `--dry-run`
   - Validate values
   - Check syntax
   - Test templates

3. Resource Management
   - Monitor resource usage
   - Check quota limits
   - Verify node capacity
   - Review PDB status

4. Security Checks
   - Verify RBAC permissions
   - Check service account
   - Validate secrets
   - Review network policies

## See Also
- [Deployments Configuration](./deployments.md)
- [Services Configuration](./services.md)
- [Values Example](./values-example.yaml)
