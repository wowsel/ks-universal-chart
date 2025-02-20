# Advanced Features

This guide covers advanced features and patterns available in the ks-universal chart.

## Table of Contents
- [Values Inheritance](#values-inheritance)
- [Complex Deployments](#complex-deployments)
- [Advanced Scheduling](#advanced-scheduling)
- [Security Features](#security-features)
- [Resource Management](#resource-management)
- [Custom Configurations](#custom-configurations)

## Values Inheritance

The chart supports sophisticated values inheritance and merging:

```yaml
# Global settings
deploymentsGeneral:
  securityContext:
    runAsNonRoot: true
  probes:
    livenessProbe:
      httpGet:
        path: /health
        port: http

# Generic settings
generic:
  ingressesGeneral:
    domain: example.com
    annotations:
      nginx.ingress.kubernetes.io/proxy-body-size: "10m"

# Specific deployment (inherits and overrides)
deployments:
  my-app:
    # Inherits global securityContext
    containers:
      main:
        # Override specific probe
        probes:
          livenessProbe:
            httpGet:
              path: /custom-health
```

## Complex Deployments

### Multi-container Pods

```yaml
deployments:
  complex-app:
    containers:
      main:
        image: main-app
        imageTag: v1.0.0
        ports:
          http:
            containerPort: 8080
      
      # Sidecar containers
      cache:
        image: redis
        imageTag: "6.2"
        ports:
          redis:
            containerPort: 6379
        volumeMounts:
          - name: cache-data
            mountPath: /data
    
    volumes:
      - name: logs
        emptyDir: {}
      - name: cache-data
        emptyDir: {}

### Service Mesh Integration

```yaml
deployments:
  my-app:
    podAnnotations:
      sidecar.istio.io/inject: "true"
    
    containers:
      main:
        image: my-app
        imageTag: v1.0.0
        ports:
          http:
            containerPort: 8080
```

### Custom Metrics

```yaml
deployments:
  my-app:
    autoCreateServiceMonitor: true
    containers:
      main:
        ports:
          http-metrics:
            containerPort: 9090
    
    serviceMonitor:
      endpoints:
        - port: http-metrics
          interval: 15s
          metricRelabelings:
            - sourceLabels: [__name__]
              regex: '^container_.*'
              action: drop
```

## Tips and Best Practices

1. **Resource Management**
   - Always specify resource requests and limits
   - Use HPA for dynamic scaling
   - Consider using PodDisruptionBudget

2. **Security**
   - Enable securityContext
   - Use non-root users
   - Implement network policies
   - Regularly rotate secrets

3. **High Availability**
   - Use pod anti-affinity
   - Implement proper health checks
   - Configure appropriate update strategies

4. **Monitoring**
   - Set up comprehensive metrics
   - Configure proper alert rules
   - Use appropriate scraping intervals

5. **Configuration**
   - Use ConfigMaps for configuration
   - Implement proper secret management
   - Consider using external configuration stores

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- [cert-manager Documentation](https://cert-manager.io/docs/)Port: 6379
      
      metrics:
        image: prometheus-exporter
        imageTag: v1.0.0
        ports:
          metrics:
            containerPort: 9090
```

### Advanced Init Containers

```yaml
deployments:
  my-app:
    initContainers:
      setup:
        image: busybox
        command: ['sh', '-c', 'setup-script.sh']
        env:
          - name: SETUP_VAR
            value: "value"
        volumeMounts:
          - name: config
            mountPath: /config
      
      wait-for-db:
        image: postgres
        command: 
          - '/bin/sh'
          - '-c'
          - |
            until pg_isready -h $DB_HOST -p $DB_PORT; do
              echo "waiting for database"
              sleep 2
            done
```

## Advanced Scheduling

### Node Affinity

```yaml
deployments:
  my-app:
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: kubernetes.io/instance-type
                  operator: In
                  values:
                    - m5.large
                    - m5.xlarge

      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/name: my-app
              topologyKey: kubernetes.io/hostname
```

### Topology Spread Constraints

```yaml
deployments:
  my-app:
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: my-app
```

## Security Features

### Pod Security Context

```yaml
deployments:
  secure-app:
    securityContext:
      runAsUser: 1000
      runAsGroup: 3000
      fsGroup: 2000
      runAsNonRoot: true
      seccompProfile:
        type: RuntimeDefault
    
    containers:
      main:
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
              - ALL
```

### Network Policies

```yaml
networkPolicies:
  app:
    spec:
      podSelector:
        matchLabels:
          app.kubernetes.io/name: my-app
      policyTypes:
        - Ingress
        - Egress
      ingress:
        - from:
            - podSelector:
                matchLabels:
                  app.kubernetes.io/name: frontend
      egress:
        - to:
            - podSelector:
                matchLabels:
                  app.kubernetes.io/name: database
```

## Resource Management

### Advanced HPA Configuration

```yaml
deployments:
  my-app:
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
        - type: Resource
          resource:
            name: memory
            target:
              type: AverageValue
              averageValue: 500Mi
      behavior:
        scaleUp:
          stabilizationWindowSeconds: 300
          policies:
            - type: Percent
              value: 100
              periodSeconds: 15
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
            - type: Percent
              value: 50
              periodSeconds: 60
```

### Resource Quotas

```yaml
resourceQuotas:
  app-quota:
    hard:
      requests.cpu: "4"
      requests.memory: 8Gi
      limits.cpu: "8"
      limits.memory: 16Gi
```

## Custom Configurations

### Advanced Environment Variables

```yaml
deployments:
  my-app:
    containers:
      main:
        env:
          # From Field
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          
          # From Resource Field
          - name: CPU_REQUEST
            valueFrom:
              resourceFieldRef:
                containerName: main
                resource: requests.cpu
          
          # From ConfigMap
          - name: CONFIG_VAR
            valueFrom:
              configMapKeyRef:
                name: app-config
                key: config-var
                optional: true
```

### Dynamic Volume Configuration

```yaml
deployments:
  my-app:
    volumes:
      - name: config
        configMap:
          name: app-config
          items:
            - key: config.json
              path: config/config.json
      
      - name: certs
        secret:
          secretName: app-certs
          defaultMode: 0400
      
      - name: cache
        emptyDir:
          medium: Memory
          sizeLimit: 1Gi
```

### Advanced Probes

```yaml
deployments:
  my-app:
    containers:
      main:
        probes:
          startupProbe:
            httpGet:
              path: /startup
              port: http
            failureThreshold: 30
            periodSeconds: 10
          
          livenessProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - curl -f http://localhost:8080/health
            initialDelaySeconds: 30
            periodSeconds: 10
          
          readinessProbe:
            tcpSocket:
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
            successThreshold: 2
```

## Advanced Use Cases

### Blue-Green Deployments

```yaml
deployments:
  blue:
    replicas: 3
    containers:
      main:
        image: my-app
        imageTag: v1.0.0
  
  green:
    replicas: 0  # Start with 0 replicas
    containers:
      main:
        image: my-app
        imageTag: v2.0.0

services:
  app:
    type: ClusterIP
    selector:
      deployment: blue  # Switch to green for cutover
    ports:
      - name: http
        port: 80
        targetPort: http
```

### Canary Deployments

```yaml
deployments:
  stable:
    replicas: 9
    containers:
      main:
        image: my-app
        imageTag: v1.0.0
  
  canary:
    replicas: 1
    containers:
      main:
        image: my-app
        imageTag: v2.0.0
```

### Sidecar Patterns

```yaml
deployments:
  my-app:
    containers:
      main:
        image: my-app
        imageTag: v1.0.0
      
      # Logging sidecar
      logging:
        image: fluent-bit
        imageTag: v1.9.0
        volumeMounts:
          - name: logs
            mountPath: /var/log
      
      # Metrics sidecar
      metrics:
        image: prometheus-exporter
        imageTag: v1.0.0
        ports:
          metrics:
            containerPort: 9090
      
      # Cache sidecar
      cache:
        image: redis
        imageTag: "6.2"
        ports:
          redis:
            container