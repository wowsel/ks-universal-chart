# ServiceAccount Configuration

## Overview
ServiceAccounts provide an identity for processes running in pods and can be used to control access to the Kubernetes API and other services.

## Structure
```yaml
deployments:
  deployment-name:
    serviceAccount:
      annotations: {}    # Optional ServiceAccount annotations
```

## Configuration Parameters

### Basic Configuration
- `serviceAccount`: Enable ServiceAccount creation
- `serviceAccount.annotations`: Additional annotations for the ServiceAccount

### Integration with Deployment
The ServiceAccount name will match the deployment name for simplified management.

## Examples

### Basic ServiceAccount
```yaml
deployments:
  web-app:
    serviceAccount: {}    # Create ServiceAccount with default settings
```

### With Cloud Provider Integration
```yaml
deployments:
  backend:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/my-role"
```

### Complete Application Setup
```yaml
deployments:
  full-stack:
    serviceAccount:
      annotations:
        iam.gke.io/gcp-service-account: "my-sa@project.iam.gserviceaccount.com"
    containers:
      app:
        image: application
        imageTag: v1.0
```

## Cloud Provider Examples

### AWS EKS
```yaml
deployments:
  aws-app:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/service-role"
```

### Google GKE
```yaml
deployments:
  gke-app:
    serviceAccount:
      annotations:
        iam.gke.io/gcp-service-account: "service-account@project.iam.gserviceaccount.com"
```

### Azure AKS
```yaml
deployments:
  azure-app:
    serviceAccount:
      annotations:
        azure.workload.identity/client-id: "00000000-0000-0000-0000-000000000000"
```

## Common Use Cases

### S3 Access
```yaml
deployments:
  s3-reader:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/s3-reader"
    containers:
      app:
        image: s3-utility
        imageTag: v1.0
```

### Database Access
```yaml
deployments:
  db-manager:
    serviceAccount:
      annotations:
        vault.hashicorp.com/role: "database-role"
    containers:
      app:
        image: db-manager
        imageTag: v1.0
```

### Multiple Service Integration
```yaml
deployments:
  multi-cloud:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/multi-service"
        iam.gke.io/gcp-service-account: "cross-cloud@project.iam.gserviceaccount.com"
```

## Best Practices

1. Security
   - Follow principle of least privilege
   - Regularly rotate credentials
   - Use namespace isolation
   - Monitor ServiceAccount usage

2. Cloud Integration
   - Use cloud provider's managed identity services
   - Configure appropriate role bindings
   - Document required permissions
   - Implement proper rotation policies

3. Management
   - Use meaningful names
   - Document service account purposes
   - Regular access review
   - Clean up unused accounts

4. Integration
   - Configure appropriate RBAC
   - Consider pod security policies
   - Plan for secret management
   - Account for cross-namespace access

## Notes
- ServiceAccount names match deployment names
- Automatic mounting of API credentials
- Consider pod security context
- Plan for credential rotation
- Account for cross-cluster access

## Security Considerations
1. Token Automation
2. Role Binding Scope
3. Secret Management
4. Access Reviews

## See Also
- [Deployments Configuration](./deployments.md)
- [Configs Configuration](./configs.md)
