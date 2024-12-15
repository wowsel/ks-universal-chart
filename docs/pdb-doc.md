# PDB (Pod Disruption Budget) Configuration

## Overview
Pod Disruption Budget (PDB) ensures high availability of applications during voluntary cluster operations like node drains or upgrades.

## Structure
```yaml
deployments:
  deployment-name:
    pdb:
      minAvailable: 1        # Either minAvailable
      # maxUnavailable: 1    # Or maxUnavailable
```

## Configuration Parameters

### Primary Settings
- `minAvailable`: Minimum number of pods that must be available (absolute number or percentage)
- `maxUnavailable`: Maximum number of pods that can be unavailable (absolute number or percentage)

Note: Only one of `minAvailable` or `maxUnavailable` should be specified.

## Examples

### Absolute Numbers
```yaml
deployments:
  web-app:
    replicas: 5
    pdb:
      minAvailable: 3    # Always keep at least 3 pods running
```

### Percentage Values
```yaml
deployments:
  api-service:
    replicas: 10
    pdb:
      minAvailable: "50%"    # Always keep at least 50% of pods running
```

### Using maxUnavailable
```yaml
deployments:
  backend:
    replicas: 8
    pdb:
      maxUnavailable: 2    # No more than 2 pods can be unavailable
```

### Critical Service
```yaml
deployments:
  database:
    replicas: 3
    pdb:
      maxUnavailable: 1    # Only one pod can be unavailable at a time
```

### High Availability Setup
```yaml
deployments:
  mission-critical:
    replicas: 5
    pdb:
      minAvailable: "80%"    # Keep at least 80% of pods running
    hpa:
      minReplicas: 5
      maxReplicas: 10
```

## Common Use Cases

### Standard Web Application
```yaml
deployments:
  web:
    replicas: 4
    pdb:
      maxUnavailable: 1    # Rolling updates with one pod at a time
```

### Batch Processing
```yaml
deployments:
  worker:
    replicas: 10
    pdb:
      minAvailable: "40%"    # Allow more disruption for non-critical workloads
```

### Stateful Applications
```yaml
deployments:
  database:
    replicas: 3
    pdb:
      minAvailable: 2    # Maintain quorum
```

## Best Practices

1. Choosing Between minAvailable and maxUnavailable
   - Use `minAvailable` when you need to guarantee a minimum service level
   - Use `maxUnavailable` when you want to limit the impact of disruptions
   - Prefer percentages for deployments that scale up and down

2. Setting Appropriate Values
   - Consider the application's high availability requirements
   - Account for node maintenance and cluster upgrades
   - Align with application's scaling patterns

3. Combining with Other Resources
   - Consider HPA configuration when setting PDB
   - Ensure enough resources across nodes
   - Account for node affinity and anti-affinity rules

4. High Availability Considerations
   - Set stricter PDBs for critical services
   - Consider zone distribution
   - Account for maintenance windows

## Examples with Multiple Components

### Multi-Tier Application
```yaml
deployments:
  frontend:
    replicas: 4
    pdb:
      maxUnavailable: 1
  
  backend:
    replicas: 6
    pdb:
      minAvailable: "75%"
  
  cache:
    replicas: 3
    pdb:
      minAvailable: 2
```

### Microservices Setup
```yaml
deployments:
  auth-service:
    replicas: 4
    pdb:
      minAvailable: "50%"
  
  payment-service:
    replicas: 5
    pdb:
      maxUnavailable: 1
  
  notification-service:
    replicas: 3
    pdb:
      minAvailable: 2
```

## Notes
- PDB only protects against voluntary disruptions
- Cannot protect against involuntary disruptions (hardware failure, kernel panics)
- Works in conjunction with deployment replicas and node management
- Values should be less than the total number of replicas
- Percentage values should be quoted in YAML

## Common Pitfalls
1. Setting PDB too strictly can prevent node drains
2. Not accounting for HPA scaling when using absolute numbers
3. Setting values equal to replica count (prevents all disruptions)
4. Not considering multi-zone deployments

## See Also
- [Deployments Configuration](./deployments.md)
- [HPA Configuration](./hpa.md)
