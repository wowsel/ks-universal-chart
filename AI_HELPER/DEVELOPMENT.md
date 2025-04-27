# Development Guide for KS Universal Chart

This guide is specifically designed for AI agents to understand how to contribute to and extend the ks-universal Helm chart. It provides detailed information about the chart's architecture, development principles, and extension patterns.

## Chart Architecture

The ks-universal chart follows a modular architecture with these key components:

### 1. Templates

The chart is organized into template files for each Kubernetes resource type:

- `deployment.yaml`: Handles Deployment resources
- `service.yaml`: Handles Service resources
- `ingress.yaml`: Handles Ingress resources
- `cronjob.yaml`: Handles CronJob resources
- `job.yaml`: Handles Job resources
- `dexauthenticator.yaml`: Handles DexAuthenticator resources
- `servicemonitor.yaml`: Handles ServiceMonitor resources
- `pdb.yaml`: Handles PodDisruptionBudget resources
- `pvc.yaml`: Handles PersistentVolumeClaim resources
- `hpa.yaml`: Handles HorizontalPodAutoscaler resources
- `certificate.yaml`: Handles Certificate resources
- `configs.yaml`: Handles ConfigMap resources
- `serviceaccount.yaml`: Handles ServiceAccount resources

### 2. Helper Templates

Helper templates provide reusable functions:

- `_helpers.tpl`: Contains helper functions for resource generation
- `_validation.tpl`: Contains validation functions

### 3. Values Processing Flow

The chart processes values in this order:

1. **Validation**: Validates provided values
2. **Global Defaults**: Applies global settings
3. **Resource Generation**: Generates resources
4. **Auto-creation**: Creates related resources

## Development Principles

When extending or modifying the chart, follow these principles:

### 1. Backward Compatibility

- **Principle**: Maintain backward compatibility with existing values
- **Implementation**:
  - New features should be opt-in
  - Default behaviors should not change
  - Use feature flags for new functionality

### 2. Validation First

- **Principle**: Always validate input before processing
- **Implementation**:
  - Add validation functions in `_validation.tpl`
  - Use the `fail` function with clear error messages
  - Check required fields, ranges, and relationships

### 3. Modular Design

- **Principle**: Keep components isolated and reusable
- **Implementation**:
  - Use helper functions for shared logic
  - Pass contexts explicitly to functions
  - Avoid global variables

### 4. Inheritance Model

- **Principle**: Support global settings with local overrides
- **Implementation**:
  - Use the `merge` function for combining configurations
  - Check local settings before applying global defaults
  - Document inheritance behaviors

### 5. Clear Naming

- **Principle**: Use consistent and descriptive names
- **Implementation**:
  - Follow Kubernetes naming conventions
  - Use prefixes to group related functions
  - Document function purposes

## Adding New Features

When adding new features to the chart, follow these steps:

### 1. Values Schema Design

1. **Define the Schema**:
   - Design the values schema for the new feature
   - Place it in the appropriate section of values.yaml
   - Document it in VALUES_SCHEMA.md

2. **Backward Compatibility**:
   - Ensure new values are optional with sensible defaults
   - Avoid changing existing value semantics

### 2. Validation Functions

1. **Create Validation Functions**:
   - Add validation functions in `_validation.tpl`
   - Validate required fields and constraints
   - Provide clear error messages

2. **Integrate with Existing Validation**:
   - Add calls to new validation functions in existing flows
   - Update the main validation function if needed

### 3. Helper Functions

1. **Create Helper Functions**:
   - Implement helper functions in `_helpers.tpl`
   - Follow the naming convention: `ks-universal.<function-name>`
   - Document the function purpose and parameters

2. **Testing Helpers**:
   - Test helper functions with various inputs
   - Verify error handling

### 4. Template Implementation

1. **Create or Update Templates**:
   - Create a new template file or update existing ones
   - Use helper functions for common operations
   - Follow the same structure as existing templates

2. **Auto-creation Integration**:
   - If the feature supports auto-creation, integrate with existing auto-creation mechanisms

### 5. Documentation

1. **Update Documentation**:
   - Document the new feature in VALUES_SCHEMA.md
   - Add examples to README.md
   - Create test cases in TESTING.md

## Extending Existing Resources

To extend an existing resource type, follow these steps:

### 1. Identify Extension Points

1. **Values Schema**:
   - Identify where in the values schema to add new options
   - Ensure compatibility with existing options

2. **Template Processing**:
   - Identify which template files need modification
   - Locate the specific sections to modify

### 2. Implement Extensions

1. **Update Values Schema**:
   - Add new options to the values schema
   - Document new options in VALUES_SCHEMA.md

2. **Extend Validation**:
   - Add validation for new options
   - Integrate with existing validation

3. **Update Templates**:
   - Modify templates to use the new options
   - Maintain backward compatibility

### 3. Testing

1. **Create Test Cases**:
   - Create test values for the extension
   - Test with various configurations

2. **Verify Rendering**:
   - Verify that templates render correctly
   - Check for potential conflicts

## Working with Common Patterns

The chart uses several common patterns that you should follow when extending it:

### 1. Auto-creation Pattern

For resources that can be auto-created from other resources:

```yaml
{{- if $config.autoCreateX }}
{{- include "ks-universal.autoX" (dict "name" $name "config" $config "root" $) }}
{{- end }}
```

Implementation:

```yaml
{{- define "ks-universal.autoX" -}}
{{- $name := .name -}}
{{- $config := .config -}}
{{- $root := .root -}}

apiVersion: x/v1
kind: X
metadata:
  name: {{ $name }}
  labels:
    {{- include "ks-universal.labels" (dict "Chart" $root.Chart "Release" $root.Release "name" $name) | nindent 4 }}
spec:
  # Resource-specific configuration
{{- end }}
```

### 2. Inheritance Pattern

For applying global defaults with local overrides:

```yaml
{{- $defaulted := include "ks-universal.xDefaults" (dict "x" $local "general" $global) | fromYaml }}
```

Implementation:

```yaml
{{- define "ks-universal.xDefaults" -}}
{{- $x := .x | default dict -}}
{{- $general := .general | default dict -}}
{{- $result := deepCopy $x -}}

{{- if $general.field -}}
  {{- if not $x.field -}}
    {{- $result = merge $result (dict "field" $general.field) -}}
  {{- end -}}
{{- end -}}

{{- toYaml $result -}}
{{- end }}
```

### 3. Validation Pattern

For validating configuration:

```yaml
{{- define "ks-universal.validateX" -}}
{{- $name := .name -}}
{{- $config := .config -}}

{{- if not $config -}}
{{- fail (printf "X %s: configuration must not be empty" $name) -}}
{{- end -}}

{{- if not $config.requiredField -}}
{{- fail (printf "X %s: requiredField is required" $name) -}}
{{- end -}}
{{- end }}
```

## Handling Dependencies

The chart handles dependencies in these ways:

### 1. Internal Dependencies

For dependencies between components within the chart:

- Use auto-creation to create related resources
- Pass context between templates using the `dict` function
- Use helpers to ensure consistent configuration

### 2. Optional External Dependencies

For optional dependencies on external systems:

- Use feature flags to enable/disable integration
- Validate the presence of required configuration
- Document requirements clearly

## Best Practices for AI Agents

As an AI agent working on this chart, follow these best practices:

### 1. Test-First Development

1. Create test values that exercise the new functionality
2. Implement the feature to pass the tests
3. Verify rendering with `helm template`

### 2. Incremental Changes

1. Make small, focused changes
2. Test each change before proceeding
3. Document each change clearly

### 3. Follow Existing Patterns

1. Study the existing code for patterns
2. Maintain consistent style and structure
3. Use existing helpers when possible

### 4. Validation Focus

1. Implement thorough validation
2. Provide clear error messages
3. Validate at the earliest possible point

## Template Development Examples

### Example 1: Adding a New Resource Type

Let's say we want to add support for StatefulSet resources:

1. **Define the Schema in values.yaml**:

```yaml
# StatefulSets
statefulSets:
  database:
    replicas: 3
    containers:
      db:
        image: postgres
        imageTag: 13
        ports:
          db:
            containerPort: 5432
    volumeClaimTemplates:
      - name: data
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 10Gi
```

2. **Create Validation Function in _validation.tpl**:

```yaml
{{- define "ks-universal.validateStatefulSet" -}}
{{- $name := .name -}}
{{- $config := .config -}}

{{- if not $config.containers -}}
{{- fail (printf "StatefulSet %s: containers configuration is required" $name) -}}
{{- end -}}

{{- range $containerName, $container := $config.containers -}}
{{- include "ks-universal.validateContainer" (dict "containerName" $containerName "container" $container "context" (printf "StatefulSet %s" $name) "root" $.root) -}}
{{- end -}}

{{- if not $config.volumeClaimTemplates -}}
{{- fail (printf "StatefulSet %s: volumeClaimTemplates is required" $name) -}}
{{- end -}}
{{- end -}}
```

3. **Create Template File statefulset.yaml**:

```yaml
{{- include "ks-universal.validate" . -}}
{{- if .Values.statefulSets }}
{{- range $name, $config := .Values.statefulSets }}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ $name }}
  labels:
    {{- include "ks-universal.labels" (dict "Chart" $.Chart "Release" $.Release "name" $name) | nindent 4 }}
spec:
  replicas: {{ $config.replicas | default 1 }}
  selector:
    matchLabels:
      {{- include "ks-universal.componentLabels" (dict "name" $name "root" $) | nindent 6 }}
  serviceName: {{ $name }}
  template:
    metadata:
      labels:
        {{- include "ks-universal.labels" (dict "Chart" $.Chart "Release" $.Release "name" $name) | nindent 8 }}
    spec:
      containers:
      {{- include "ks-universal.containers" (dict "root" $ "containers" $config.containers) | nindent 8 | trimPrefix "\n" }}
  volumeClaimTemplates:
  {{- range $config.volumeClaimTemplates }}
  - metadata:
      name: {{ .name }}
    spec:
      accessModes: {{ toYaml .accessModes | nindent 8 }}
      resources:
        {{ toYaml .resources | nindent 8 }}
      {{- if .storageClassName }}
      storageClassName: {{ .storageClassName }}
      {{- end }}
  {{- end }}
---
{{- end }}
{{- end }}
```

4. **Update the Main Validation Function**:

```yaml
{{- define "ks-universal.validate" -}}
{{- include "ks-universal.validateContext" . -}}

{{/* Validate StatefulSets */}}
{{- range $name, $config := .Values.statefulSets -}}
{{- include "ks-universal.validateStatefulSet" (dict "name" $name "config" $config "root" $) -}}
{{- end -}}

{{/* Existing validation */}}
{{- end -}}
```

### Example 2: Extending Existing Resource

Let's say we want to add podAntiAffinity to deployments:

1. **Update the Values Schema**:

```yaml
deployments:
  app:
    # Existing configuration
    podAntiAffinity:
      type: hard  # or soft
      topologyKey: "kubernetes.io/hostname"
```

2. **Create Helper Function in _helpers.tpl**:

```yaml
{{- define "ks-universal.podAntiAffinity" -}}
{{- $name := .name -}}
{{- $config := .config -}}

{{- if eq $config.type "hard" }}
requiredDuringSchedulingIgnoredDuringExecution:
- labelSelector:
    matchLabels:
      app.kubernetes.io/component: {{ $name }}
  topologyKey: {{ $config.topologyKey | default "kubernetes.io/hostname" }}
{{- else }}
preferredDuringSchedulingIgnoredDuringExecution:
- weight: 100
  podAffinityTerm:
    labelSelector:
      matchLabels:
        app.kubernetes.io/component: {{ $name }}
    topologyKey: {{ $config.topologyKey | default "kubernetes.io/hostname" }}
{{- end }}
{{- end }}
```

3. **Update the processAffinity Function**:

```yaml
{{- define "ks-universal.processAffinity" -}}
{{- $config := .config }}
{{- $deploymentName := .deploymentName }}
{{- $general := .general }}
{{- $result := dict }}

{{/* Existing code */}}

{{/* Add podAntiAffinity */}}
{{- if $config.podAntiAffinity }}
  {{- $podAntiAffinity := include "ks-universal.podAntiAffinity" (dict "name" $deploymentName "config" $config.podAntiAffinity) | fromYaml }}
  {{- $_ := set $result "podAntiAffinity" $podAntiAffinity }}
{{- end }}

{{- toYaml $result }}
{{- end }}
```

### Example 3: Adding Auto-creation Feature

Let's say we want to add auto-creation of NetworkPolicy:

1. **Update the Values Schema**:

```yaml
deployments:
  app:
    # Existing configuration
    autoCreateNetworkPolicy: true
    networkPolicy:
      ingress:
        - from:
            - podSelector:
                matchLabels:
                  app: frontend
      egress:
        - to:
            - namespaceSelector:
                matchLabels:
                  name: kube-system
```

2. **Create Helper Function in _helpers.tpl**:

```yaml
{{- define "ks-universal.autoNetworkPolicy" -}}
{{- $deploymentName := .deploymentName -}}
{{- $deploymentConfig := .deploymentConfig -}}
{{- $root := .root -}}

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ $deploymentName }}
  labels:
    {{- include "ks-universal.labels" (dict "Chart" $root.Chart "Release" $root.Release "name" $deploymentName) | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "ks-universal.componentLabels" (dict "name" $deploymentName "root" $root) | nindent 6 }}
  {{- with $deploymentConfig.networkPolicy.ingress }}
  ingress:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $deploymentConfig.networkPolicy.egress }}
  egress:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
```

3. **Update deployment.yaml**:

```yaml
{{/* Auto-create NetworkPolicy if enabled */}}
{{- if $deploymentConfig.autoCreateNetworkPolicy }}
{{- include "ks-universal.autoNetworkPolicy" (dict "deploymentName" $deploymentName "deploymentConfig" $deploymentConfig "root" $) }}
---
{{- end }}
```

## Debugging and Troubleshooting

When debugging chart issues, follow these steps:

### 1. Template Rendering

Debug template rendering with:

```bash
helm template ./charts/ks-universal -f values.yaml --debug
```

Look for:
- Incorrect indentation
- Missing sections
- Incorrect variable references

### 2. Validation Logic

Debug validation logic with:

```bash
helm template ./charts/ks-universal -f values.yaml
```

Look for:
- Clear error messages
- Validation failures
- Unexpected behavior

### 3. Value Processing

Debug value processing by adding debugging statements:

```yaml
{{ $debug := merge (dict "context" $context) (dict "config" $config) | toYaml }}
{{/* {{ fail $debug }} */}}
```

### 4. Helper Function Testing

Test helper functions by invoking them directly:

```yaml
{{- $result := include "ks-universal.helperFunction" (dict "param1" "value1" "param2" "value2") | fromYaml -}}
{{/* {{ fail ($result | toYaml) }} */}}
```

## Conclusion

When developing and extending the ks-universal chart, prioritize:

1. **Backward Compatibility**: Ensure existing configurations continue to work
2. **Validation**: Provide thorough validation with clear error messages
3. **Consistent Patterns**: Follow established patterns in the codebase
4. **Documentation**: Update documentation for all changes
5. **Testing**: Create comprehensive test cases

By following these guidelines, AI agents can effectively contribute to and extend the ks-universal chart while maintaining its quality and usability. 