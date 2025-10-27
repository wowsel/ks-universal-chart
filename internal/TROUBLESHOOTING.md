# Troubleshooting Guide for KS Universal Chart

This guide provides AI agents with solutions to common issues encountered when working with the ks-universal Helm chart. It's organized by problem category to help quickly diagnose and resolve issues.

## Validation Errors

### 1. Missing Required Fields

**Error:**
```
Error: execution error at (ks-universal/templates/deployment.yaml): Deployment app: Container main: image is required
```

**Solution:**
- Ensure all required fields are specified in the values file
- For containers, `image` and `imageTag` are always required
- Check nested objects like `containers` under a deployment
- Example correction:
```yaml
deployments:
  app:
    containers:
      main:
        image: "nginx"  # Add this
        imageTag: "latest"  # Add this
```

### 2. Invalid Port Configuration

**Error:**
```
Error: execution error at (ks-universal/templates/deployment.yaml): Deployment app: Container main: port http must be between 1 and 65535
```

**Solution:**
- Ensure port values are within the valid range (1-65535)
- Check for typos or non-numeric values in port definitions
- Example correction:
```yaml
ports:
  http:
    containerPort: 8080  # Fix invalid value
```

### 3. Duplicate Port Names

**Error:**
```
Error: execution error at (ks-universal/templates/deployment.yaml): Deployment app: Container main: duplicate port name http
```

**Solution:**
- Ensure port names are unique within each container
- Rename duplicate ports with descriptive names
- Example correction:
```yaml
ports:
  http:
    containerPort: 8080
  http-admin:  # Changed from duplicate 'http'
    containerPort: 8081
```

### 4. Environment Variable Missing Value

**Error:**
```
Error: execution error at (ks-universal/templates/deployment.yaml): Deployment app: Container main: either value or valueFrom must be specified for environment variable LOG_LEVEL
```

**Solution:**
- Provide either a direct value or valueFrom for environment variables
- Check for typos in environment variable definitions
- Example correction:
```yaml
env:
  - name: LOG_LEVEL
    value: "info"  # Add this
```

### 5. Invalid PDB Configuration

**Error:**
```
Error: execution error at (ks-universal/templates/pdb.yaml): PDB app: cannot specify both minAvailable and maxUnavailable
```

**Solution:**
- Use either `minAvailable` or `maxUnavailable` in PDB configuration, not both
- Remove one of the conflicting fields
- Example correction:
```yaml
pdbConfig:
  maxUnavailable: 1
  # Remove minAvailable: 2
```

## Rendering Issues

### 1. Indentation Problems

**Symptom:**
- Generated YAML has incorrect indentation
- Kubernetes returns syntax errors when applying resources

**Solution:**
- Check the nindent values in template functions
- Ensure helper templates return properly indented content
- Use the `nindent` function to add indentation
- Example correction in a template:
```yaml
spec:
  selector:
    matchLabels:
      {{- include "ks-universal.componentLabels" (dict "name" $name "root" $) | nindent 6 }}
```

### 2. Missing Resource Sections

**Symptom:**
- Expected sections are missing from generated resources
- Kubernetes returns validation errors

**Solution:**
- Check conditional statements in templates
- Ensure values are properly structured in your values file
- Verify helper function usage and parameters
- Example correction:
```yaml
# Make sure the condition is correctly formatted
{{- if and $config.ingress $config.ingress.enabled }}
# Resource definition
{{- end }}
```

### 3. Empty or Null Values

**Symptom:**
- Generated YAML contains `null` or empty values
- Kubernetes returns validation errors

**Solution:**
- Use the `default` function to provide default values
- Use conditional statements to omit empty sections
- Example corrections:
```yaml
# Use default for potentially nil values
replicas: {{ $config.replicas | default 1 }}

# Conditionally include sections
{{- if $config.annotations }}
annotations:
  {{- toYaml $config.annotations | nindent 4 }}
{{- end }}
```

## Inheritance Issues

### 1. Global Settings Not Applied

**Symptom:**
- Global settings are not reflected in generated resources
- Local settings appear to be missing

**Solution:**
- Check the merge logic in relevant helper templates
- Verify the structure of global settings in values file
- Ensure values are passed correctly to helper functions
- Example correction in helper template:
```yaml
{{- define "ks-universal.deploymentDefaults" -}}
{{- $deployment := .deployment }}
{{- $general := .general }}
{{- $result := deepCopy $deployment }}
{{- if $general }}
  {{- if $general.securityContext }}
    {{- $result = merge $result (dict "securityContext" $general.securityContext) }}
  {{- end }}
  # Add more merges for other settings
{{- end }}
{{- toYaml $result }}
{{- end }}
```

### 2. Overrides Not Working

**Symptom:**
- Local settings are not overriding global settings
- Global values appear instead of local values

**Solution:**
- Check the order of merges in helper templates
- Ensure local values are given precedence in merge operations
- Example correction:
```yaml
# Correct merge order: general values first, then overwrite with local values
{{- $result := merge (deepCopy $general) $local }}
```

### 3. Missing Context in Helper Templates

**Symptom:**
- Helper templates produce incorrect or incomplete output
- Variables are undefined in templates

**Solution:**
- Pass complete context to helper templates
- Include required fields in dictionary parameters
- Example correction:
```yaml
{{- include "ks-universal.helper" (dict "name" $name "config" $config "root" $) }}
```

## Auto-creation Issues

### 1. Auto-created Resources Missing

**Symptom:**
- Resources that should be auto-created are missing
- No error messages are displayed

**Solution:**
- Check that auto-creation flags are properly set
- Verify conditional statements in templates
- Ensure required configurations for auto-created resources exist
- Example correction:
```yaml
# Set the flag correctly
autoCreateServiceMonitor: true

# Add required configuration
serviceMonitor:
  interval: "15s"
```

### 2. Auto-created Resources Have Incorrect Configuration

**Symptom:**
- Resources are created but with incorrect or incomplete configuration
- Resources fail validation in Kubernetes

**Solution:**
- Check helper templates for auto-resource creation
- Verify that values are correctly merged and applied
- Example correction:
```yaml
# Add missing configuration
ingress:
  hosts:
    - host: "app.example.com"
      paths:
        - path: "/"
          pathType: "Prefix"
```

### 3. Service Selector Does Not Match Pods

**Symptom:**
- Services cannot connect to pods
- Endpoints are not created for services

**Solution:**
- Check label and selector templates
- Ensure consistent naming in templates
- Example correction in template:
```yaml
# Ensure selector matches pod labels
selector:
  matchLabels:
    {{- include "ks-universal.componentLabels" (dict "name" $name "root" $) | nindent 4 }}
```

## Domain Construction Issues

### 1. Incorrect Domain Names

**Symptom:**
- Ingress hosts do not have expected domain names
- Domain construction doesn't work as expected

**Solution:**
- Check the domain construction logic
- Verify global domain settings
- Ensure subdomain values are correctly set
- Example correction:
```yaml
# Set global domain
generic:
  ingressesGeneral:
    domain: "example.com"

# Use subdomain correctly
ingress:
  hosts:
    - subdomain: "app"  # Will become app.example.com
      paths:
        - path: "/"
          pathType: "Prefix"
```

### 2. Mixed Host and Subdomain Usage

**Symptom:**
- Some hosts use full domain, others use constructed domains
- Inconsistent domain behavior

**Solution:**
- Standardize domain approach for consistency
- Use host for explicit domains, subdomain for constructed domains
- Example correction:
```yaml
ingress:
  hosts:
    - subdomain: "app"  # Will become app.example.com with domain construction
      paths:
        - path: "/"
          pathType: "Prefix"
    - host: "custom.domain.com"  # Explicit full domain, no construction
      paths:
        - path: "/"
          pathType: "Prefix"
```

## ServiceMonitor Issues

### 1. ServiceMonitor Not Discovering Targets

**Symptom:**
- Prometheus is not discovering targets from ServiceMonitors
- No metrics are being collected

**Solution:**
- Check ServiceMonitor labels (must match Prometheus instance selector)
- Verify port names and service selectors
- Example correction:
```yaml
serviceMonitor:
  labels:
    prometheus: "app-prometheus"  # Must match Prometheus instance selector
  endpoints:
    - port: http-metrics  # Must match service port name
      path: /metrics
```

### 2. Wrong Metrics Endpoint

**Symptom:**
- Prometheus is connecting but not receiving metrics
- Scrape errors in Prometheus logs

**Solution:**
- Verify container exposes metrics on the correct port and path
- Check ServiceMonitor endpoint configuration
- Example correction:
```yaml
# Make sure container exposes metrics port
ports:
  http-metrics:  # Special port name for metrics
    containerPort: 9090

# Configure ServiceMonitor with correct path
serviceMonitor:
  path: "/metrics"  # Correct metrics path
```

## Certificate Issues

### 1. Certificate Not Being Created

**Symptom:**
- Certificate resources are not created
- TLS not working for ingress resources

**Solution:**
- Check cert-manager is installed in the cluster
- Verify autoCreateCertificate flag is set
- Ensure issuer or clusterIssuer is correctly configured
- Example correction:
```yaml
autoCreateCertificate: true
certificate:
  clusterIssuer: "letsencrypt-prod"  # Must exist in the cluster
```

### 2. Certificate Not Being Issued

**Symptom:**
- Certificate resources exist but remain in a pending state
- TLS not working for ingress resources

**Solution:**
- Check cert-manager logs for issuing errors
- Verify DNS configuration for domains
- Ensure issuer or clusterIssuer is correctly configured
- Example correction:
```yaml
# Fix issuer configuration
certificate:
  clusterIssuer: "letsencrypt-prod"  # Correct existing issuer name
```

### 3. Certificate and Ingress Domain Mismatch

**Symptom:**
- Certificate is issued for the wrong domains
- TLS handshake errors in browser

**Solution:**
- Ensure ingress hosts and certificate domains match
- Use same domain construction logic for both
- Example correction:
```yaml
# Ensure ingress and certificate use same domain logic
autoCreateIngress: true
autoCreateCertificate: true
ingress:
  hosts:
    - subdomain: "app"  # Will be used for both ingress and certificate
      paths:
        - path: "/"
          pathType: "Prefix"
```

## Secret Reference Issues

### 1. Secret Reference Not Found

**Error:**
```
Error: execution error at (ks-universal/templates/deployment.yaml): Deployment app: Container main: referenced secretRef 'database' not found in .Values.secretRefs
```

**Solution:**
- Ensure the referenced secretRef is defined in the top-level secretRefs section
- Check for typos in secretRef names
- Example correction:
```yaml
# Add the missing secretRef
secretRefs:
  database:  # Name referenced in container
    - name: DB_HOST
      secretKeyRef:
        name: db-credentials
        key: host
```

### 2. Secret Key Reference Invalid

**Symptom:**
- Pods fail to start with env var reference errors
- Kubernetes events show secret key not found

**Solution:**
- Verify secret exists in the cluster with correct keys
- Check secretKeyRef name and key values
- Example correction:
```yaml
secretRefs:
  database:
    - name: DB_HOST
      secretKeyRef:
        name: db-credentials  # Must exist in cluster
        key: host  # Must exist in secret
```

## Template Logic Errors

### 1. Helper Function Parameters

**Symptom:**
- Helper functions produce unexpected output
- No error messages but incorrect resources

**Solution:**
- Check parameter names and values passed to helper functions
- Ensure dictionaries contain all required keys
- Example correction:
```yaml
# Ensure all required parameters are provided
{{- include "ks-universal.helper" (dict "name" $name "config" $config "root" $) }}
```

### 2. fromYaml/toYaml Conversion Issues

**Symptom:**
- Helper functions produce invalid YAML or unexpected structure
- Template rendering fails with conversion errors

**Solution:**
- Check data types before conversion
- Ensure helper templates return valid YAML
- Use the `deepCopy` function to avoid modifying shared data
- Example correction:
```yaml
# First convert to YAML, then parse it back
{{- $yamlString := include "ks-universal.helper" (dict "param" $value) }}
{{- $parsedYaml := fromYaml $yamlString }}
```

### 3. Variable Scope Issues

**Symptom:**
- Variables defined in loops or conditionals are not accessible
- Templates produce unexpected results

**Solution:**
- Be aware of variable scope limitations in Helm templates
- Define variables in parent scope when needed
- Use `$_` variable for assignment results to avoid clutter
- Example correction:
```yaml
{{- $result := dict }}
{{- range $key, $value := $data }}
  {{- $_ := set $result $key $value }}
{{- end }}
```

## Debugging Strategies

### 1. Template Debugging

Use the `helm template` command with `--debug` flag to examine template output:

```bash
helm template ./charts/ks-universal -f values.yaml --debug
```

This shows both the rendered templates and intermediate values.

### 2. Print Debugging

Add temporary debugging output to templates:

```yaml
{{/* Debug output - remove before committing */}}
{{- $debug := dict "context" . "config" $config -}}
{{/* {{ fail ($debug | toYaml) }} */}}
```

Uncommenting the `fail` line will abort rendering and display the debug variables.

### 3. Isolate Templates

Test individual helper templates in isolation:

```yaml
{{/* Test helper template */}}
{{- $testInput := dict "param1" "value1" "param2" "value2" -}}
{{- $testResult := include "ks-universal.helper" $testInput | fromYaml -}}
{{/* {{ fail ($testResult | toYaml) }} */}}
```

### 4. Step-by-Step Debugging

When dealing with complex templates, add step markers:

```yaml
{{/* Step 1: Process input */}}
{{- $step1 := deepCopy $input -}}

{{/* Step 2: Apply transformations */}}
{{- $step2 := merge $step1 (dict "newField" "newValue") -}}

{{/* Step 3: Convert to final format */}}
{{- $result := $step2 -}}
```

### 5. Trace Template Inclusion

Add trace points to see which templates are being processed:

```yaml
{{- define "ks-universal.helper" -}}
{{/* TRACE: Entering ks-universal.helper */}}
{{- $result := dict -}}
# ... function logic ...
{{/* TRACE: Exiting ks-universal.helper */}}
{{- toYaml $result -}}
{{- end -}}
```

## Common Patterns for Fixing Issues

### 1. Missing Required Configuration

```yaml
# Problem: Missing required configuration
deployments:
  app:
    # Missing containers section

# Solution: Add required configuration
deployments:
  app:
    containers:
      main:
        image: "nginx"
        imageTag: "latest"
        ports:
          http:
            containerPort: 80
```

### 2. Incorrect Inheritance

```yaml
# Problem: Global settings not applied
generic:
  deploymentsGeneral:
    securityContext:
      runAsNonRoot: true

deployments:
  app:
    # Missing inheritance mechanism

# Solution: Fix template or explicitly include settings
deployments:
  app:
    securityContext:
      runAsNonRoot: true
    containers:
      main:
        image: "nginx"
        imageTag: "latest"
```

### 3. Auto-creation Configuration

```yaml
# Problem: Auto-creation enabled but missing configuration
deployments:
  app:
    autoCreateIngress: true
    # Missing ingress configuration

# Solution: Add required configuration for auto-created resource
deployments:
  app:
    autoCreateIngress: true
    ingress:
      hosts:
        - subdomain: "app"
          paths:
            - path: "/"
              pathType: "Prefix"
    containers:
      main:
        image: "nginx"
        imageTag: "latest"
        ports:
          http:
            containerPort: 80
```

### 4. Service and Port Configuration

```yaml
# Problem: Service targets non-existent port
deployments:
  app:
    autoCreateService: true
    containers:
      main:
        image: "nginx"
        imageTag: "latest"
        # Missing port definition

# Solution: Add port configuration
deployments:
  app:
    autoCreateService: true
    containers:
      main:
        image: "nginx"
        imageTag: "latest"
        ports:
          http:
            containerPort: 80
```

### 5. Environment Variable Configuration

```yaml
# Problem: Invalid environment variable configuration
deployments:
  app:
    containers:
      main:
        image: "nginx"
        imageTag: "latest"
        env:
          - name: LEVEL
            # Missing value or valueFrom

# Solution: Add value to environment variable
deployments:
  app:
    containers:
      main:
        image: "nginx"
        imageTag: "latest"
        env:
          - name: LEVEL
            value: "debug"
```

## Helm Chart Upgrade Issues

### 1. Breaking Changes in Templates

**Symptom:**
- Chart upgrade fails with template errors
- Previously working configurations no longer work

**Solution:**
- Check chart version release notes for breaking changes
- Update values to match new template requirements
- Example update process:
  1. Review release notes
  2. Create a diff of old and new values
  3. Apply necessary changes to values
  4. Test with `helm template` before upgrading

### 2. Resource Replacement Issues

**Symptom:**
- Upgrade attempts to delete and recreate resources instead of updating
- Data loss or service disruption during upgrade

**Solution:**
- Check for immutable field changes
- Use strategic merges to update resources
- Example approach:
  1. Extract current values: `helm get values -n namespace release-name`
  2. Update only changed fields
  3. Use `--atomic` flag for safe upgrades: `helm upgrade --atomic -f values.yaml release-name ./chart`

## Conclusion

When troubleshooting the ks-universal chart:

1. **Start with Validation**: Check validation errors first, they provide the most direct clues
2. **Examine Template Rendering**: Verify that templates generate the expected resources
3. **Check Inheritance**: Ensure global and local settings are properly combined
4. **Verify Auto-creation**: Check auto-creation flags and related configurations
5. **Test Incrementally**: Make one change at a time and test after each change

By following these guidelines, AI agents can effectively diagnose and resolve issues with the ks-universal chart while maintaining its functionality and reliability. 