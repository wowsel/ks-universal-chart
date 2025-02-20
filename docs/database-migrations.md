# Database Migrations

This guide explains how to handle database migrations using the ks-universal chart.

## Overview

The chart provides built-in support for database migrations through:
- Pre-deployment migration jobs
- Shared configuration and secrets
- Container reuse
- Failure handling

## Basic Configuration

```yaml
deployments:
  my-app:
    # Enable migrations
    migrations:
      enabled: true
      args:
        - "migrate"
        - "up"
      backoffLimit: 3    # Number of retries
    
    # Main application configuration
    containers:
      main:
        image: my-app
        imageTag: v1.0.0
        env:
          - name: DB_HOST
            value: postgresql
          - name: DB_NAME
            value: myapp
          - name: DB_USER
            valueFrom:
              secretKeyRef:
                name: db-secrets
                key: DB_USER
```

## Migration Job Features

- Runs before application deployment
- Uses same container configuration
- Supports custom arguments
- Configurable retry logic
- Shares environment variables and secrets

## Complete Example

```yaml
configs:
  db-secrets:
    type: secret
    data:
      DB_PASSWORD: your-db-password
      DB_USER: your-db-user

deployments:
  my-app:
    # Migration configuration
    migrations:
      enabled: true
      args: ["migrate", "up"]
      backoffLimit: 3
    
    # Main application
    containers:
      main:
        image: my-app
        imageTag: v1.0.0
        env:
          - name: DB_HOST
            value: postgresql
          - name: DB_NAME
            value: myapp
        # Use shared secrets
        envFrom:
          - type: secret
            configName: db-secrets
        
        # Optional: specify migration command
        command:
          - "/app/my-app"
```

## Advanced Configuration

### Multiple Migration Steps

```yaml
deployments:
  my-app:
    migrations:
      enabled: true
      steps:
        - name: schema
          args: ["migrate", "schema"]
          backoffLimit: 2
        - name: data
          args: ["migrate", "data"]
          backoffLimit: 3
```

### Custom Environment for Migrations

```yaml
deployments:
  my-app:
    migrations:
      enabled: true
      args: ["migrate", "up"]
      env:
        - name: MIGRATION_TIMEOUT
          value: "300"
        - name: MIGRATION_LOCK_TIMEOUT
          value: "60"
```

### Migration with Dependencies

```yaml
deployments:
  my-app:
    migrations:
      enabled: true
      args: ["migrate", "up"]
      initContainers:
        - name: wait-for-db
          image: alpine
          command: 
            - sh 
            - -c
            - |
              until nc -z postgresql 5432; do
                echo "waiting for db"
                sleep 1
              done
```

## Best Practices

1. **Error Handling**
   - Set appropriate `backoffLimit`
   - Use initialization containers
   - Monitor migration logs

2. **Security**
   - Use secrets for credentials
   - Consider read-only filesystem
   - Limit permissions

3. **Performance**
   - Optimize migration scripts
   - Use appropriate resource limits
   - Consider database load

4. **Operations**
   - Keep migrations idempotent
   - Version control migrations
   - Plan for rollbacks

## Common Patterns

### Simple Migration
```yaml
migrations:
  enabled: true
  args: ["migrate", "up"]
  backoffLimit: 3
```

### Complex Migration
```yaml
migrations:
  enabled: true
  args: ["migrate", "up"]
  backoffLimit: 3
  env:
    - name: MIGRATION_TIMEOUT
      value: "300"
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

### Migration with Health Check
```yaml
migrations:
  enabled: true
  args: ["migrate", "up"]
  initContainers:
    - name: db-ready
      image: alpine
      command: 
        - sh 
        - -c
        - |
          until nc -z postgresql 5432; do
            echo "waiting for db"
            sleep 1
          done
```

## Troubleshooting

### Common Issues

1. **Migration Failures**
   - Check database connectivity
   - Verify credentials
   - Review migration logs
   - Check resource constraints

2. **Timeout Issues**
   - Increase job timeout
   - Check database performance
   - Monitor resource usage

3. **Lock Conflicts**
   - Implement lock timeout
   - Check concurrent migrations
   - Review database locks

### Debugging

View migration logs:
```bash
kubectl logs job/my-app-migrations -n my-namespace
```

Check job status:
```bash
kubectl describe job/my-app-migrations -n my-namespace
```

## Security Considerations

1. **Credentials**
   - Use Kubernetes secrets
   - Rotate credentials regularly
   - Limit access permissions

2. **Network**
   - Use network policies
   - Secure database connections
   - Consider VPC security

3. **Audit**
   - Log migration operations
   - Track schema changes
   - Monitor access patterns