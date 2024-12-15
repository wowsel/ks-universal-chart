# Use Cases

## Overview
This document provides examples of common deployment scenarios using the ks-universal Helm chart. Each use case includes a complete configuration example and explanation.

## Table of Contents
1. [Web Application with Database](#web-application-with-database)
2. [Microservices Architecture](#microservices-architecture)
3. [API Gateway with Multiple Backends](#api-gateway-with-multiple-backends)
4. [Background Worker with Message Queue](#background-worker-with-message-queue)
5. [Stateful Application](#stateful-application)
6. [Machine Learning Pipeline](#machine-learning-pipeline)

## Web Application with Database

### Scenario
A typical web application with frontend, backend, and database components.

```yaml
configs:
  app-config:
    type: configMap
    data:
      APP_ENV: production
      DB_HOST: postgres
      REDIS_HOST: redis

  app-secrets:
    type: secret
    data:
      DB_PASSWORD: your-secure-password
      SESSION_KEY: random-session-key

deployments:
  frontend:
    replicas: 3
    autoCreateService: true
    containers:
      nginx:
        image: frontend-app
        imageTag: v1.0
        ports:
          http:
            containerPort: 80
    hpa:
      minReplicas: 3
      maxReplicas: 10
      metrics:
        - type: Resource
          resource:
            name: cpu
            target:
              type: Utilization
              averageUtilization: 70

  backend:
    replicas: 4
    autoCreateService: true
    containers:
      api:
        image: backend-app
        imageTag: v1.0
        ports:
          http:
            containerPort: 8080
          http-metrics:
            containerPort: 9090
        envFrom:
          - type: configMap
            configName: app-config
          - type: secret
            configName: app-secrets
    migrations:
      enabled: true
      args: ["python", "manage.py", "migrate"]
    hpa:
      minReplicas: 2
      maxReplicas: 8

ingresses:
  frontend:
    ingressClassName: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    tls:
      - secretName: frontend-tls
        hosts:
          - example.com
    hosts:
      - host: example.com
        paths:
          - path: /
            pathType: Prefix
          - path: /api
            pathType: Prefix
            port: 8080
```

## Microservices Architecture

### Scenario
Multiple independent services communicating through internal network.

```yaml
deployments:
  auth-service:
    replicas: 2
    autoCreateService: true
    containers:
      auth:
        image: auth-service
        imageTag: v1.0
        ports:
          http:
            containerPort: 8080
          http-metrics:
            containerPort: 9090
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/auth-role

  user-service:
    replicas: 3
    autoCreateService: true
    containers:
      user:
        image: user-service
        imageTag: v1.0
        ports:
          http:
            containerPort: 8081
    hpa:
      minReplicas: 2
      maxReplicas: 5

  notification-service:
    replicas: 2
    autoCreateService: true
    containers:
      notification:
        image: notification-service
        imageTag: v1.0
        ports:
          http:
            containerPort: 8082
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/notification-role

  api-gateway:
    replicas: 4
    autoCreateService: true
    containers:
      gateway:
        image: api-gateway
        imageTag: v1.0
        ports:
          http:
            containerPort: 80
    pdb:
      minAvailable: "50%"
```

## API Gateway with Multiple Backends

### Scenario
API Gateway routing traffic to different backend services.

```yaml
deployments:
  gateway:
    replicas: 3
    autoCreateService: true
    containers:
      nginx:
        image: nginx
        imageTag: latest
        ports:
          http:
            containerPort: 80
        volumeMounts:
          - name: nginx-config
            mountPath: /etc/nginx/conf.d
    volumes:
      - name: nginx-config
        configMap:
          name: nginx-config

  service-a:
    replicas: 2
    autoCreateService: true
    containers:
      app:
        image: service-a
        imageTag: v1.0
        ports:
          http:
            containerPort: 8080

  service-b:
    replicas: 2
    autoCreateService: true
    containers:
      app:
        image: service-b
        imageTag: v1.0
        ports:
          http:
            containerPort: 8081

configs:
  nginx-config:
    type: configMap
    data:
      nginx.conf: |
        server {
          listen 80;
          location /api/v1 {
            proxy_pass http://service-a:8080;
          }
          location /api/v2 {
            proxy_pass http://service-b:8081;
          }
        }
```

## Background Worker with Message Queue

### Scenario
Worker processing messages from a queue with autoscaling based on queue length.

```yaml
deployments:
  worker:
    replicas: 2
    containers:
      processor:
        image: worker
        imageTag: v1.0
        env:
          - name: QUEUE_URL
            valueFrom:
              configMapKeyRef:
                name: queue-config
                key: url
    hpa:
      minReplicas: 1
      maxReplicas: 10
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
              averageValue: 100
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/sqs-consumer

configs:
  queue-config:
    type: configMap
    data:
      url: https://sqs.region.amazonaws.com/queue/worker-tasks
```

## Stateful Application

### Scenario
Stateful application with persistent storage and ordered deployment.

```yaml
deployments:
  database:
    replicas: 3
    containers:
      postgres:
        image: postgres
        imageTag: "13"
        ports:
          postgresql:
            containerPort: 5432
        env:
          - name: POSTGRES_PASSWORD
            valueFrom:
              secretKeyRef:
                name: db-credentials
                key: password
        volumeMounts:
          - name: data
            mountPath: /var/lib/postgresql/data
    volumeClaimTemplates:
      - metadata:
          name: data
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
    pdb:
      minAvailable: 2
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/db-backup

configs:
  db-credentials:
    type: secret
    data:
      password: secure-database-password
```

## Machine Learning Pipeline

### Scenario
ML pipeline with model training and inference services.

```yaml
deployments:
  model-trainer:
    containers:
      trainer:
        image: model-trainer
        imageTag: v1.0
        resources:
          requests:
            cpu: 4
            memory: 16Gi
            nvidia.com/gpu: 1
          limits:
            cpu: 8
            memory: 32Gi
            nvidia.com/gpu: 1
    nodeSelector:
      cloud.google.com/gke-accelerator: nvidia-tesla-t4

  inference-api:
    replicas: 3
    autoCreateService: true
    containers:
      api:
        image: inference-api
        imageTag: v1.0
        ports:
          http:
            containerPort: 8080
        resources:
          requests:
            cpu: 2
            memory: 4Gi
          limits:
            cpu: 4
            memory: 8Gi
    hpa:
      minReplicas: 2
      maxReplicas: 10
      metrics:
        - type: Resource
          resource:
            name: cpu
            target:
              type: Utilization
              averageUtilization: 70

jobs:
  data-preprocessor:
    activeDeadlineSeconds: 3600
    containers:
      preprocessor:
        image: data-preprocessor
        imageTag: v1.0
        args:
          - --input-path
          - gs://data-bucket/raw
          - --output-path
          - gs://data-bucket/processed
```

Each use case includes:
- Complete configuration example
- Relevant components and their interactions
- Specific features used (HPA, PDB, ServiceAccount, etc.)
- Best practices for the specific scenario

## See Also
- [Values Example](./values-example.yaml)
- [Troubleshooting Guide](./troubleshooting.md)
