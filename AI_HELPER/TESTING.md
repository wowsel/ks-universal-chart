# Testing Guidelines for KS Universal Chart

This document provides comprehensive testing guidelines for AI agents working with the ks-universal Helm chart. It outlines test approaches, validation methods, and common test cases.

## Testing Strategy

### 1. Test Categories

When testing the ks-universal chart, focus on these categories:

1. **Functional Tests**: Validate that resources are correctly generated from values
2. **Edge Case Tests**: Test boundary conditions and optional features
3. **Inheritance Tests**: Verify that global settings are properly inherited
4. **Validation Tests**: Confirm that validation functions correctly identify invalid configurations
5. **Integration Tests**: Test interactions between different components
6. **Upgrade Tests**: Verify that chart upgrades work correctly

### 2. Test Environments

Test the chart in different environments:

- **Minimal Kubernetes**: Basic cluster with standard components
- **Full Platform**: Cluster with Prometheus, cert-manager, and other components
- **Different Kubernetes Versions**: Test on multiple Kubernetes versions

## Test Case Development

### 1. Basic Resource Generation Tests

Verify that basic resources are correctly generated:

```yaml
# test-deployment.yaml
deployments:
  test-app:
    replicas: 1
    containers:
      main:
        image: "nginx"
        imageTag: "latest"
        ports:
          http:
            containerPort: 80
```

Test validation:
- Deployment has correct name and labels
- Container has correct image and port
- Selector labels match template labels

### 2. Auto-creation Tests

Test auto-creation features with minimal configuration:

```yaml
# test-auto-creation.yaml
deployments:
  auto-test:
    containers:
      app:
        image: "nginx"
        imageTag: "latest"
        ports:
          http:
            containerPort: 80
          metrics:
            containerPort: 9090
    autoCreateService: true
    autoCreateServiceMonitor: true
    autoCreatePdb: true
    autoCreateIngress: true
    autoCreateCertificate: true
    ingress:
      hosts:
        - subdomain: "auto"
          paths:
            - path: "/"
              pathType: "Prefix"
```

Test validation:
- Service is created with correct selectors and ports
- ServiceMonitor targets the metrics port
- PDB is created with correct selectors
- Ingress is created with correct rules
- Certificate is created for ingress hosts

### 3. Inheritance Tests

Test inheritance from global settings:

```yaml
# test-inheritance.yaml
generic:
  deploymentsGeneral:
    securityContext:
      runAsNonRoot: true
    nodeSelector:
      kubernetes.io/os: linux
  ingressesGeneral:
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
    domain: "example.com"
    ingressClassName: "nginx"

deployments:
  inherit-test:
    containers:
      app:
        image: "nginx"
        imageTag: "latest"
        ports:
          http:
            containerPort: 80
    autoCreateIngress: true
    ingress:
      hosts:
        - subdomain: "test"
          paths:
            - path: "/"
              pathType: "Prefix"
```

Test validation:
- Deployment inherits securityContext and nodeSelector
- Ingress inherits annotations and ingressClassName
- Host is constructed as "test.example.com"

### 4. Validation Tests

Test validation by providing invalid configurations:

```yaml
# test-validation-missing-image.yaml
deployments:
  invalid-test:
    containers:
      app:
        # Missing image field
        imageTag: "latest"
```

```yaml
# test-validation-invalid-port.yaml
deployments:
  invalid-test:
    containers:
      app:
        image: "nginx"
        imageTag: "latest"
        ports:
          http:
            containerPort: 99999  # Invalid port (>65535)
```

Test validation:
- Chart fails with clear error messages
- Validation errors identify specific issues

### 5. Complex Configuration Tests

Test complex configurations:

```yaml
# test-complex.yaml
generic:
  deploymentsGeneral:
    probes:
      livenessProbe:
        httpGet:
          path: /healthz
          port: http
        initialDelaySeconds: 30
        periodSeconds: 10

secretRefs:
  database:
    - name: DB_HOST
      secretKeyRef:
        name: db-creds
        key: host
    - name: DB_PASSWORD
      secretKeyRef:
        name: db-creds
        key: password

deployments:
  complex-app:
    replicas: 3
    containers:
      app:
        image: "app"
        imageTag: "v1"
        ports:
          http:
            containerPort: 8080
          http-metrics:
            containerPort: 8081
        secretRefs:
          - database
        env:
          - name: LOG_LEVEL
            value: "info"
        volumeMounts:
          - name: config-volume
            mountPath: /etc/config
            readOnly: true
      sidecar:
        image: "sidecar"
        imageTag: "v1"
        ports:
          metrics:
            containerPort: 9090
    volumes:
      - name: config-volume
        configMap:
          name: app-config
    autoCreateService: true
    autoCreateServiceMonitor: true
    autoCreatePdb: true
    pdbConfig:
      maxUnavailable: 1
```

Test validation:
- Multiple containers are created correctly
- Volumes and volumeMounts are connected correctly
- Secret references are processed correctly
- Multiple ports are handled correctly

## Testing Process

### 1. Template Rendering Tests

Use `helm template` to render the chart with test values:

```bash
helm template ./charts/ks-universal -f ./charts/ks-universal/tests/values/test-case.yaml
```

Verify that:
- All resources are rendered correctly
- Labels and selectors match
- Container specifications are correct
- Auto-created resources have correct configurations

### 2. Linting Tests

Use `helm lint` to check for structural issues:

```bash
helm lint ./charts/ks-universal -f ./charts/ks-universal/tests/values/test-case.yaml
```

### 3. Installation Tests

For comprehensive testing, install the chart in a test cluster:

```bash
helm install test-release ./charts/ks-universal -f ./charts/ks-universal/tests/values/test-case.yaml
```

Verify that:
- All resources are created in the cluster
- Resources function correctly
- Auto-created resources work together

### 4. Snapshot Testing

For efficient testing, use Helm's unittest plugin with snapshots:

```bash
# Create or update snapshots
helm unittest . -f tests/component_test.yaml -u

# Run tests against existing snapshots
helm unittest . -f tests/component_test.yaml
```

Advantages of snapshot testing:
- Simplifies complex assertions
- Captures the entire generated output for comparison
- Quickly identifies unexpected changes in rendered templates
- Makes it easy to update expected output when templates change

## Using Helm Unittest Plugin

### 1. Basic Structure of Test Files

```yaml
suite: test component name
templates:
  - template1.yaml
  - template2.yaml
tests:
  - it: should do something specific
    set:
      key1: value1
      key2: value2
    asserts:
      - isKind:
          of: Deployment
      - equal:
          path: metadata.name
          value: expected-name
      - matchSnapshot: {}
```

### 2. Common Assertion Types

- `isKind`: Check if the resource is of specified kind
- `isAPIVersion`: Verify the apiVersion of the resource
- `equal`: Check if a specific path has the expected value
- `contains`: Verify if an array/map contains specific content
- `matchSnapshot`: Compare the full or partial resource with a snapshot

### 3. Working with Multiple Documents

When a template produces multiple Kubernetes resources:

```yaml
tests:
  - it: should create multiple resources
    set:
      # values here
    asserts:
      - hasDocuments:
          count: 3
      - documentIndex: 0
        isKind:
          of: Deployment
      - documentIndex: 1
        isKind:
          of: Service
      - documentIndex: 2
        isKind:
          of: Ingress
```

## Common Test Cases

### 1. Basic Deployment

```yaml
deployments:
  basic-app:
    containers:
      app:
        image: "nginx"
        imageTag: "latest"
        ports:
          http:
            containerPort: 80
```

### 2. Web Application with Ingress

```yaml
deployments:
  web-app:
    containers:
      app:
        image: "nginx"
        imageTag: "latest"
        ports:
          http:
            containerPort: 80
    autoCreateService: true
    autoCreateIngress: true
    ingress:
      hosts:
        - host: "test.example.com"
          paths:
            - path: "/"
              pathType: "Prefix"
```

### 3. Application with Prometheus Monitoring

```yaml
deployments:
  monitored-app:
    containers:
      app:
        image: "app"
        imageTag: "v1"
        ports:
          http:
            containerPort: 8080
          http-metrics:
            containerPort: 8081
    autoCreateService: true
    autoCreateServiceMonitor: true
    serviceMonitor:
      interval: "15s"
      path: "/metrics"
```

### 4. Database with PersistentVolumeClaim

```yaml
deployments:
  database:
    containers:
      db:
        image: "postgres"
        imageTag: "13"
        ports:
          db:
            containerPort: 5432
        volumeMounts:
          - name: data
            mountPath: /var/lib/postgresql/data
            subPath: data
    volumes:
      - name: data
        persistentVolumeClaim:
          claimName: db-data
    autoCreateService: true
    autoCreatePdb: true
    pdbConfig:
      maxUnavailable: 1

persistentVolumeClaims:
  db-data:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 10Gi
```

### 5. CronJob for Backups

```yaml
cronJobs:
  backup:
    schedule: "0 2 * * *"
    containers:
      backup:
        image: "backup-tool"
        imageTag: "1.0.0"
        command: ["/bin/sh", "-c", "backup.sh"]
        env:
          - name: BACKUP_DIR
            value: "/backup"
```

## Edge Cases to Test

### 1. Multiple Ports with Same Container Port

```yaml
deployments:
  edge-case:
    containers:
      app:
        image: "app"
        imageTag: "v1"
        ports:
          http:
            containerPort: 8080
          admin:
            containerPort: 8080  # Same port as http
```

Expected behavior: Validation should fail with clear error message.

### 2. Override Global Settings

```yaml
generic:
  ingressesGeneral:
    ingressClassName: "nginx"

deployments:
  override-test:
    autoCreateIngress: true
    ingress:
      ingressClassName: "custom"  # Overrides global setting
      hosts:
        - host: "test.example.com"
          paths:
            - path: "/"
              pathType: "Prefix"
```

Expected behavior: Ingress should use "custom" ingressClassName instead of "nginx".

### 3. Complex Domain Construction

```yaml
generic:
  ingressesGeneral:
    domain: "example.com"

deployments:
  domain-test:
    autoCreateIngress: true
    ingress:
      hosts:
        - subdomain: "test"  # Should become test.example.com
          paths:
            - path: "/"
              pathType: "Prefix"
        - host: "override.domain.com"  # Explicit host, should not use domain construction
          paths:
            - path: "/"
              pathType: "Prefix"
```

Expected behavior: First host should be "test.example.com", second should be "override.domain.com".

## Test Validation Methods

### 1. Resource Existence

Check that required resources exist:

```bash
kubectl get deployments,services,ingress,servicemonitors,pdb
```

### 2. Resource Configuration

Verify resource configurations:

```bash
kubectl get deployment <name> -o yaml
kubectl get service <name> -o yaml
kubectl get ingress <name> -o yaml
```

### 3. Functionality Tests

Test that resources function correctly:

```bash
# Test service connectivity
kubectl run test --image=busybox --rm -it -- wget -qO- <service-name>:<port>

# Test ingress
curl -H "Host: <ingress-host>" http://<ingress-ip>
```

## Automated Testing

Use CI/CD for automated testing:

1. **Lint Tests**: Run `helm lint` on all test values files
2. **Template Tests**: Render templates and compare with expected outputs
3. **Validation Tests**: Verify that invalid configurations fail with correct messages
4. **Installation Tests**: Install and test in a temporary cluster
5. **Snapshot Tests**: Run unittest with snapshot comparisons

### CI/CD Configuration

Example GitHub workflow:

```yaml
name: Helm Chart Tests

on:
  push:
    paths:
      - 'charts/ks-universal/**'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Lint Chart
        run: |
          helm lint ./charts/ks-universal

  unittest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Helm unittest plugin
        run: |
          helm plugin install https://github.com/quintush/helm-unittest
      - name: Run unittest
        run: |
          helm unittest ./charts/ks-universal -f tests/*.yaml

  template-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Template Tests
        run: |
          for file in ./charts/ks-universal/tests/values/*.yaml; do
            helm template ./charts/ks-universal -f $file
          done

  validation-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validation Tests
        run: |
          for file in ./charts/ks-universal/tests/invalid-values/*.yaml; do
            if helm template ./charts/ks-universal -f $file; then
              echo "Test $file should fail but succeeded"
              exit 1
            fi
          done
```

## Test Output Analysis

When analyzing test outputs, check for:

1. **Resource Completeness**: All requested resources are created
2. **Inheritance**: Global settings are properly applied
3. **Validation Errors**: Error messages are clear and helpful
4. **Resource Relationships**: Resources reference each other correctly
5. **Default Values**: Default values are applied when not specified
6. **Snapshot Accuracy**: Snapshots correctly reflect the expected output

## Snapshot Management Best Practices

1. **Regularly Update Snapshots**: When chart templates change intentionally, update snapshots with the `-u` flag
2. **Version Control**: Keep snapshots in version control to track changes over time
3. **Review Differences**: When a snapshot test fails, carefully review the differences to understand what changed
4. **Targeted Snapshots**: Use path-specific snapshots (e.g., `matchSnapshot: { path: spec.template.spec }`) for focused testing
5. **Clean Snapshots**: Remove unused snapshots when tests are deleted or modified significantly

## Test Documentation

Document test cases with:

1. **Purpose**: What the test is validating
2. **Input**: Values file used for the test
3. **Expected Output**: Expected resources and configurations
4. **Validation Method**: How to verify the test result

Example:

```
Test: Web Application with Ingress
Purpose: Validate that a deployment with ingress is created correctly
Input: ./tests/values/web-app.yaml
Expected Output:
  - Deployment with nginx container
  - Service targeting the deployment
  - Ingress with specified host and path
Validation:
  - All resources are created
  - Ingress routes to service
  - Service selects deployment
```

## Troubleshooting Common Test Issues

### 1. Template Rendering Errors

Issue: Error when rendering templates
```
Error: template: ks-universal/templates/deployment.yaml:18:20: executing "ks-universal/templates/deployment.yaml" at <.containers>: can't evaluate field containers in type interface {}
```

Resolution:
- Check the structure of your values file
- Ensure required fields are provided
- Check for typos in field names

### 2. Validation Failures

Issue: Validation fails with error
```
Error: execution error at (ks-universal/templates/deployment.yaml): Deployment test-app: Container app: image is required
```

Resolution:
- Provide the missing required fields
- Check the validation requirements in `_validation.tpl`

### 3. Resource Inheritance Issues

Issue: Global settings not applied
```
# Ingress has nginx.ingress.kubernetes.io/ssl-redirect: "false" instead of "true"
```

Resolution:
- Check the inheritance logic in templates
- Verify global settings are correctly structured
- Look for potential overrides in local configuration

### 4. Snapshot Test Failures

Issue: Snapshot test fails with differences
```
- asserts[0] `matchSnapshot` fail
        Template:       ks-universal/templates/deployment.yaml
        Expected:
                replicas: 2
        Actual:
                replicas: 3
```

Resolution:
- If the change is expected, update snapshots with `-u` flag
- If unexpected, fix the template or values to match the expected behavior
- Review the full diff to understand all changes

### 5. Document Index Out of Range

Issue: Test tries to access a document that doesn't exist
```
- asserts[1] `isKind` fail
        Error:
        document index 2 is out of range
```

Resolution:
- Verify document count with hasDocuments assertion
- Check that your template generates the expected number of resources
- Adjust document indices to match the actual order

## Summary

Follow these testing guidelines to ensure comprehensive testing of the ks-universal chart:

1. Create a diverse set of test values files
2. Test basic functionality, edge cases, and complex configurations
3. Verify resource generation, validation, and inheritance
4. Use both static analysis (template rendering, linting) and runtime tests
5. Leverage snapshot testing for efficient verification
6. Document test cases and expected outcomes
7. Automate testing in CI/CD pipelines 