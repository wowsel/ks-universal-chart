## Dynamic Values Support

The chart supports dynamic template evaluation for certain fields using Helm's templating engine. This allows you to use template expressions in your values:

```yaml
deployments:
  web-app:
    containers:
      app:
        image: "{{ .Values.registry }}/nginx"    # Use dynamic registry
        imageTag: "{{ .Values.version }}"        # Use dynamic version

# Can be used with:
# helm install my-release . --set registry=my-registry.com --set version=1.19.0
```

### Supported Fields for Dynamic Values
- Container image
- Container imageTag
- Environment variable values
- Arguments and commands

### Example with Environment Variables
```yaml
deployments:
  app:
    containers:
      main:
        env:
          - name: REGION
            value: "{{ .Values.region }}"
          - name: ENVIRONMENT
            value: "{{ .Values.env }}"
```

This feature allows you to reuse the same values file with different parameters for different environments or configurations.

Note: Use this feature carefully as it can make your deployment configuration harder to understand and maintain.