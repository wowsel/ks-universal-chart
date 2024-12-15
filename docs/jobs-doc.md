# Jobs Configuration

## Overview
The ks-universal chart supports two types of Jobs:
1. Regular Jobs: One-time or batch processing tasks
2. Migration Jobs: Database migrations or other pre-deployment tasks

## Structure

### Regular Jobs
```yaml
jobs:
  job-name:
    activeDeadlineSeconds: 600    # Optional
    backoffLimit: 3               # Optional
    restartPolicy: Never         # Optional, defaults to Never
    containers:
      container-name:
        image: job-image
        imageTag: v1.0
        args: []                 # Optional
        env: []                 # Optional
        resources: {}           # Optional
```

### Migration Jobs
```yaml
deployments:
  app-name:
    migrations:
      enabled: true
      args: ["migrate"]
      backoffLimit: 1    # Optional, defaults to 1
```

## Configuration Parameters

### Job Settings
- `activeDeadlineSeconds`: Time limit for job execution
- `backoffLimit`: Number of retries before marking job as failed
- `restartPolicy`: Pod restart policy (Never/OnFailure)

### Container Settings
- `image`: Container image
- `imageTag`: Image tag
- `args`: Command arguments
- `env`: Environment variables
- `resources`: Resource requests and limits

## Examples

### Basic Job
```yaml
jobs:
  data-processor:
    containers:
      processor:
        image: data-processor
        imageTag: v1.0
        args:
          - --input
          - /data/input
          - --output
          - /data/output
```

### Job with Resource Limits
```yaml
jobs:
  batch-processor:
    activeDeadlineSeconds: 3600
    backoffLimit: 2
    containers:
      processor:
        image: batch-processor
        imageTag: latest
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

### Database Migration
```yaml
deployments:
  backend:
    migrations:
      enabled: true
      args:
        - python
        - manage.py
        - migrate
      backoffLimit: 3
    containers:
      app:
        image: backend-app
        imageTag: v1.0
```

### Complex Data Processing Job
```yaml
jobs:
  etl-processor:
    activeDeadlineSeconds: 7200
    backoffLimit: 5
    containers:
      etl:
        image: etl-service
        imageTag: v2.1
        args:
          - --mode=full
          - --parallel=4
        env:
          - name: DB_HOST
            valueFrom:
              configMapKeyRef:
                name: db-config
                key: host
          - name: DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: db-secrets
                key: password
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
```

### Multiple Container Job
```yaml
jobs:
  data-sync:
    containers:
      extractor:
        image: data-extractor
        imageTag: v1.0
        args: ["--source=s3"]
      transformer:
        image: data-transformer
        imageTag: v1.0
        args: ["--config=/etc/config"]
```

## Migration Jobs Specifics

### Pre-deployment Migrations
```yaml
deployments:
  web-app:
    migrations:
      enabled: true
      args:
        - npm
        - run
        - migrate
      backoffLimit: 2
    containers:
      app:
        image: web-app
        imageTag: v1.0
```

### Database Schema Update
```yaml
deployments:
  api:
    migrations:
      enabled: true
      args:
        - flask
        - db
        - upgrade
      backoffLimit: 1
    containers:
      api:
        image: api-service
        imageTag: v2.0
```

## Best Practices

1. Job Configuration
   - Set appropriate timeouts
   - Configure reasonable retry limits
   - Use resource limits
   - Consider cleanup policies

2. Migration Jobs
   - Keep migrations idempotent
   - Set conservative timeout values
   - Use appropriate logging
   - Handle failures gracefully

3. Resource Management
   - Set appropriate resource requests/limits
   - Consider cluster capacity
   - Monitor job duration
   - Clean up completed jobs

4. Error Handling
   - Set appropriate backoffLimit
   - Use meaningful exit codes
   - Implement proper logging
   - Consider notification on failure

## Notes
- Jobs are not restarted automatically
- Migration jobs run before deployment
- Consider using InitContainers for complex initialization
- Jobs should be idempotent when possible
- Clean up completed jobs to avoid resource consumption

## Migration Job Hooks
Migration jobs automatically include:
- `helm.sh/hook: pre-install,pre-upgrade`
- `helm.sh/hook-weight: "-5"`
- `helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded`

## See Also
- [Deployments Configuration](./deployments.md)
- [Configs Configuration](./configs.md)
