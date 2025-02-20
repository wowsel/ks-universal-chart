# Frequently Asked Questions

## General Questions

### How do I upgrade the chart version?
```bash
helm repo update
helm upgrade my-release ks-universal/ks-universal -f values.yaml
```

### Can I use this chart with multiple environments?
Yes, you can maintain separate value files for different environments:
```yaml
# values.prod.yaml
generic:
  ingressesGeneral:
    domain: prod.example.com

# values.staging.yaml
generic:
  ingressesGeneral:
    domain: staging.example.com
```

### How can I validate my values.yaml before applying?
```bash
helm template my-release ks-universal/ks-universal -f values.yaml
```

## Deployment Questions

### How do I expose my application externally?
Use autoCreateIngress with appropriate host configuration:
```yaml
deployments:
  my-app:
    autoCreateIngress: true
    ingress:
      hosts:
        - host: myapp.example.com
          paths:
            - path: /
              pathType: Prefix
```

### How do I set up SSL/TLS for my ingress?
Enable autoCreateCertificate:
```yaml
deployments:
  my-app:
    autoCreateIngress: true
    autoCreateCertificate: true
    certificate:
      clusterIssuer: letsencrypt-prod
```

### How do I configure resource limits?
```yaml
deployments:
  my-app:
    containers:
      main:
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
```

## Configuration Questions

### How do I share configuration between deployments?
Use deploymentsGeneral for shared settings:
```yaml
deploymentsGeneral:
  securityContext:
    runAsNonRoot: true
  probes:
    livenessProbe:
      httpGet:
        path: /health
        port: http
```

### How do I manage secrets?
Use the configs section with type: secret:
```yaml
configs:
  app-secrets:
    type: secret
    data:
      API_KEY: your-api-key
      DB_PASSWORD: your-db-password
```

### How do I configure database migrations?
Enable migrations in your deployment:
```yaml
deployments:
  my-app:
    migrations:
      enabled: true
      args: ["migrate", "up"]
      backoffLimit: 3
```

## Monitoring Questions

### How do I enable Prometheus monitoring?
Use autoCreateServiceMonitor:
```yaml
deployments:
  my-app:
    autoCreateServiceMonitor: true
    containers:
      main:
        ports:
          http-metrics:
            containerPort: 9090
```

### How do I configure custom metrics?
```yaml
serviceMonitor:
  endpoints:
    - port: http-metrics
      interval: 15s
      path: /custom-metrics
```

## Scaling Questions

### How do I configure automatic scaling?
Use HPA configuration:
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
```

### How do I ensure high availability?
1. Enable PDB:
```yaml
deployments:
  my-app:
    autoCreatePdb: true
    pdbConfig:
      minAvailable: 1
```

2. Use anti-affinity:
```yaml
deployments:
  my-app:
    autoCreateSoftAntiAffinity: true
```

## Integration Questions

### How do I use this chart with Werf?
Add dependency in Chart.yaml:
```yaml
dependencies:
  - name: ks-universal
    version: "v0.2.9"
    repository: https://wowsel.github.io/ks-universal-chart
    export-values:
      - parent: werf
        child: werf
```

Then in values.yaml:
```yaml
deployments:
  my-app:
    containers:
      main:
        image: "{{ $.Values.werf.repo }}"
        imageTag: "{{ $.Values.werf.tag.myImage }}"
```

### How do I use custom domains with ingress?
You can use either global domain or specific hosts:
```yaml
generic:
  ingressesGeneral:
    domain: example.com

deployments:
  my-app:
    ingress:
      hosts:
        - subdomain: api    # Will be api.example.com
        - host: custom.domain.com  # Custom domain
```

## Troubleshooting

### Why isn't my service accessible?
1. Check service creation:
```yaml
deployments:
  my-app:
    autoCreateService: true
    containers:
      main:
        ports:
          http:
            containerPort: 8080
```

2. Verify port configurations match

### Why aren't my certificates being created?
1. Ensure cert-manager is installed
2. Check clusterIssuer exists
3. Verify ingress configuration

### How do I debug resource issues?
1. Check resource requests and limits
2. Use kubectl describe pod
3. Review container logs

## Best Practices

### Should I use autoCreateService with autoCreateIngress?
Yes, ingress requires a service to function:
```yaml
deployments:
  my-app:
    autoCreateService: true    # Required for ingress
    autoCreateIngress: true
```

### How should I organize my values files?
Maintain separate files for:
- Base configuration (values.yaml)
- Environment-specific (values.prod.yaml, values.staging.yaml)
- Secret configuration (values.secrets.yaml)