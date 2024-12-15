# Configs Configuration

## Overview
The ks-universal chart supports creating both ConfigMaps and Secrets through the `configs` section. This provides a unified interface for managing application configuration data.

## Structure
```yaml
configs:
  config-name:
    type: configMap  # or 'secret'
    data:
      key1: value1
      key2: value2
```

## ConfigMap vs Secret

### ConfigMap
Used for non-sensitive configuration data:
```yaml
configs:
  app-config:
    type: configMap
    data:
      database.host: "db.example.com"
      database.port: "5432"
```

### Secret
Used for sensitive data (values will be automatically base64 encoded):
```yaml
configs:
  app-secrets:
    type: secret
    data:
      api-key: "my-secret-key"
      database.password: "secure-password"
```

## Usage in Deployments

### Environment Variables from ConfigMap/Secret
```yaml
deployments:
  web-app:
    containers:
      app:
        envFrom:
          - type: configMap
            configName: app-config
        env:
          - name: API_KEY
            valueFrom:
              secretKeyRef:
                name: app-secrets
                key: api-key
```

### Individual Environment Variables
```yaml
containers:
  app:
    env:
      - name: DB_HOST
        valueFrom:
          configMapKeyRef:
            name: app-config
            key: database.host
```

## Examples

### Application Configuration
```yaml
configs:
  app-config:
    type: configMap
    data:
      app.env: "production"
      app.debug: "false"
      app.log_level: "info"

  app-secrets:
    type: secret
    data:
      session.key: "random-session-key"
      encryption.key: "encryption-key-value"
```

### Database Configuration
```yaml
configs:
  db-config:
    type: configMap
    data:
      host: "postgresql.default.svc.cluster.local"
      port: "5432"
      database: "myapp"

  db-credentials:
    type: secret
    data:
      username: "app_user"
      password: "secure-password"
```

### Mixed Configuration
```yaml
configs:
  redis-config:
    type: configMap
    data:
      redis.conf: |
        maxmemory 256mb
        maxmemory-policy allkeys-lru
        
  app-mixed-config:
    type: configMap
    data:
      settings.json: |
        {
          "cache": {
            "enabled": true,
            "ttl": 3600
          },
          "api": {
            "timeout": 30,
            "retry": 3
          }
        }
```

## Best Practices

1. Configuration Organization
   - Group related configurations together
   - Use meaningful config and key names
   - Separate sensitive and non-sensitive data

2. Secret Management
   - Use secrets for any sensitive information
   - Keep secret values out of version control
   - Consider using external secret management solutions

3. Configuration Structure
   - Use consistent naming conventions
   - Keep configurations modular
   - Document configuration options

## Pre-install and Pre-upgrade Hooks
Configs are automatically set up with pre-install and pre-upgrade hooks to ensure they are created before other resources that might depend on them.

## Notes
- Config names must be unique within a namespace
- Secret values are automatically base64 encoded
- ConfigMap values are stored as-is
- Maximum size limit for ConfigMaps and Secrets is 1MB
- Consider breaking up large configurations into multiple resources

## See Also
- [Deployments Configuration](./deployments.md)
- [Services Configuration](./services.md)
