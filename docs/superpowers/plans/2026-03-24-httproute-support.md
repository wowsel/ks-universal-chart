# HTTPRoute (Gateway API) Support — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Gateway API HTTPRoute support to the ks-universal Helm chart with standalone definitions, global defaults, and auto-creation from deployments.

**Architecture:** New `httproute.yaml` template iterating over `httpRoutes` map, `httpRouteDefaults` helper for merging global defaults, `autoHttpRoute` helper for deployment auto-creation. Reuses existing `computedIngressHost`, `mergeLabels`, `mergeAnnotations` helpers. Validation added to `_validation.tpl`.

**Tech Stack:** Helm templates (Go templates), helm-unittest, Gateway API v1

**Spec:** `docs/superpowers/specs/2026-03-24-httproute-support-design.md`

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `charts/ks-universal/templates/httproute.yaml` | Standalone HTTPRoute rendering |
| Modify | `charts/ks-universal/templates/_helpers.tpl` | `httpRouteDefaults` and `autoHttpRoute` helpers |
| Modify | `charts/ks-universal/templates/_validation.tpl` | `validateHttpRoute` + wire into `validate` |
| Modify | `charts/ks-universal/templates/deployment.yaml` | `autoCreateHttpRoute` conditional block |
| Modify | `charts/ks-universal/values.yaml` | Add `httpRoutes: {}` default |
| Create | `charts/ks-universal/tests/httproute_test.yaml` | Unit tests for standalone HTTPRoute |
| Create | `charts/ks-universal/tests/httproute_auto_create_test.yaml` | Unit tests for auto-create from deployments |

---

### Task 1: Add `httpRoutes: {}` to values.yaml and create `httpRouteDefaults` helper

**Files:**
- Modify: `charts/ks-universal/values.yaml:5` (add after `ingresses: {}`)
- Modify: `charts/ks-universal/templates/_helpers.tpl:195` (add after `ingressDefaults`)

- [ ] **Step 1: Add `httpRoutes` to values.yaml**

In `charts/ks-universal/values.yaml`, add after `ingresses: {}` (line 5):

```yaml
httpRoutes: {}
```

- [ ] **Step 2: Add `httpRouteDefaults` helper to `_helpers.tpl`**

Insert after the `ingressDefaults` helper (after line 195 in `_helpers.tpl`):

```gotemplate
{{- define "ks-universal.httpRouteDefaults" -}}
  {{- $httpRoute := .httpRoute | default dict }}
  {{- $general := .general | default dict }}
  {{- $result := deepCopy $httpRoute }}

  {{- /* Inherit global annotations (merge, resource-level wins) */ -}}
  {{- if $general.annotations }}
    {{- $result = merge $result (dict "annotations" (merge (default dict $httpRoute.annotations) $general.annotations)) }}
  {{- end }}

  {{- /* parentRefs: route-level fully replaces global, not a merge */ -}}
  {{- if and (not $httpRoute.parentRefs) $general.parentRefs }}
    {{- $_ := set $result "parentRefs" $general.parentRefs }}
  {{- end }}

  {{- toYaml $result }}
{{- end }}
```

- [ ] **Step 3: Verify chart still renders existing resources**

Run: `helm template test-release charts/ks-universal -f charts/ks-universal/tests/values/certificate_test.yaml 2>&1 | head -5`
Expected: renders without errors

- [ ] **Step 4: Commit**

```bash
git add charts/ks-universal/values.yaml charts/ks-universal/templates/_helpers.tpl
git commit -m "feat(httproute): add httpRoutes to values and httpRouteDefaults helper"
```

---

### Task 2: Create standalone `httproute.yaml` template

**Files:**
- Create: `charts/ks-universal/templates/httproute.yaml`

- [ ] **Step 1: Write unit test for basic standalone HTTPRoute**

Create `charts/ks-universal/tests/httproute_test.yaml`:

```yaml
suite: test httproute
templates:
  - httproute.yaml
tests:
  - it: should create an HTTPRoute with full configuration
    set:
      generic:
        ingressesGeneral:
          domain: "example.org"
        httpRoutesGeneral:
          parentRefs:
            - name: shared-gateway
              namespace: gateway-system
          annotations:
            global-annotation: "true"
      httpRoutes:
        my-app:
          hostnames:
            - subdomain: my-app
          rules:
            - matches:
                - path:
                    type: PathPrefix
                    value: /api
              backendRefs:
                - name: my-app
                  port: 8080
                  weight: 100
          annotations:
            custom-annotation: "true"
    asserts:
      - isKind:
          of: HTTPRoute
      - equal:
          path: apiVersion
          value: gateway.networking.k8s.io/v1
      - equal:
          path: metadata.name
          value: my-app
      - equal:
          path: spec.parentRefs[0].name
          value: shared-gateway
      - equal:
          path: spec.parentRefs[0].namespace
          value: gateway-system
      - equal:
          path: spec.hostnames[0]
          value: my-app.example.org
      - equal:
          path: spec.rules[0].matches[0].path.type
          value: PathPrefix
      - equal:
          path: spec.rules[0].matches[0].path.value
          value: /api
      - equal:
          path: spec.rules[0].backendRefs[0].name
          value: my-app
      - equal:
          path: spec.rules[0].backendRefs[0].port
          value: 8080
      - equal:
          path: spec.rules[0].backendRefs[0].weight
          value: 100
      - equal:
          path: metadata.annotations.custom-annotation
          value: "true"
      - equal:
          path: metadata.annotations.global-annotation
          value: "true"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `helm unittest charts/ks-universal -f tests/httproute_test.yaml`
Expected: FAIL (template not found)

- [ ] **Step 3: Create `httproute.yaml` template**

Create `charts/ks-universal/templates/httproute.yaml`:

```gotemplate
{{- include "ks-universal.validate" . -}}
{{- if .Values.httpRoutes }}
{{- range $routeName, $routeConfig := .Values.httpRoutes }}
{{- $defaultedRoute := include "ks-universal.httpRouteDefaults" (dict "httpRoute" $routeConfig "general" (index ($.Values.generic | default dict) "httpRoutesGeneral" | default dict)) | fromYaml }}
{{- $globalDomain := "" }}
{{- if and $.Values.generic $.Values.generic.ingressesGeneral }}
  {{- $globalDomain = $.Values.generic.ingressesGeneral.domain | default "" | trim }}
{{- end }}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ $routeName }}
  labels:
    {{- include "ks-universal.labels" (dict "Chart" $.Chart "Release" $.Release "name" $routeName) | nindent 4 }}
    {{- $extraLabels := include "ks-universal.mergeLabels" (dict "root" $ "resourceLabels" $routeConfig.labels) }}
    {{- if $extraLabels }}
    {{- $extraLabels | nindent 4 }}
    {{- end }}
  {{- $mergedAnnotations := include "ks-universal.mergeAnnotations" (dict "root" $ "resourceAnnotations" $defaultedRoute.annotations) }}
  {{- if $mergedAnnotations }}
  annotations:
    {{- $mergedAnnotations | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- toYaml $defaultedRoute.parentRefs | nindent 4 }}
  hostnames:
    {{- range $defaultedRoute.hostnames }}
    - {{ include "ks-universal.computedIngressHost" (dict "host" .host "subdomain" .subdomain "globalDomain" $globalDomain) | trim | quote }}
    {{- end }}
  rules:
    {{- range $rule := $defaultedRoute.rules }}
    - matches:
        {{- range $match := $rule.matches }}
        - path:
            type: {{ $match.path.type | default "PathPrefix" }}
            value: {{ $match.path.value | default "/" }}
          {{- if $match.headers }}
          headers:
            {{- range $header := $match.headers }}
            - name: {{ $header.name }}
              value: {{ $header.value | quote }}
              {{- if $header.type }}
              type: {{ $header.type }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if $match.queryParams }}
          queryParams:
            {{- range $qp := $match.queryParams }}
            - name: {{ $qp.name }}
              value: {{ $qp.value | quote }}
              {{- if $qp.type }}
              type: {{ $qp.type }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
      backendRefs:
        {{- if $rule.backendRefs }}
        {{- range $ref := $rule.backendRefs }}
        - name: {{ $ref.name | default $routeName }}
          port: {{ $ref.port | default 80 }}
          {{- if $ref.weight }}
          weight: {{ $ref.weight }}
          {{- end }}
        {{- end }}
        {{- else }}
        - name: {{ $routeName }}
          port: 80
        {{- end }}
    {{- end }}
---
{{- end }}
{{- end }}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `helm unittest charts/ks-universal -f tests/httproute_test.yaml`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add charts/ks-universal/templates/httproute.yaml charts/ks-universal/tests/httproute_test.yaml
git commit -m "feat(httproute): add standalone HTTPRoute template with unit tests"
```

---

### Task 3: Add more standalone HTTPRoute tests

**Files:**
- Modify: `charts/ks-universal/tests/httproute_test.yaml`

- [ ] **Step 1: Add test for per-route parentRefs override**

Append to `charts/ks-universal/tests/httproute_test.yaml`:

```yaml
  - it: should override global parentRefs with per-route parentRefs
    set:
      generic:
        ingressesGeneral:
          domain: "example.org"
        httpRoutesGeneral:
          parentRefs:
            - name: shared-gateway
              namespace: gateway-system
      httpRoutes:
        my-app:
          parentRefs:
            - name: custom-gateway
              namespace: custom-ns
              sectionName: https
          hostnames:
            - subdomain: my-app
          rules:
            - matches:
                - path:
                    type: PathPrefix
                    value: /
              backendRefs:
                - name: my-app
                  port: 8080
    asserts:
      - equal:
          path: spec.parentRefs[0].name
          value: custom-gateway
      - equal:
          path: spec.parentRefs[0].namespace
          value: custom-ns
      - equal:
          path: spec.parentRefs[0].sectionName
          value: https
```

- [ ] **Step 2: Add test for full host (not subdomain)**

```yaml
  - it: should use full host when specified
    set:
      generic:
        httpRoutesGeneral:
          parentRefs:
            - name: gw
              namespace: gw-ns
      httpRoutes:
        my-app:
          hostnames:
            - host: custom.example.com
          rules:
            - matches:
                - path:
                    type: Exact
                    value: /health
              backendRefs:
                - name: my-app
                  port: 3000
    asserts:
      - equal:
          path: spec.hostnames[0]
          value: custom.example.com
```

- [ ] **Step 3: Add test for default backendRef (name and port)**

```yaml
  - it: should default backendRef name to route name and port to 80
    set:
      generic:
        ingressesGeneral:
          domain: "example.org"
        httpRoutesGeneral:
          parentRefs:
            - name: gw
              namespace: gw-ns
      httpRoutes:
        my-svc:
          hostnames:
            - subdomain: my-svc
          rules:
            - matches:
                - path:
                    type: PathPrefix
                    value: /
    asserts:
      - equal:
          path: spec.rules[0].backendRefs[0].name
          value: my-svc
      - equal:
          path: spec.rules[0].backendRefs[0].port
          value: 80
```

- [ ] **Step 4: Add test for traffic splitting with multiple backendRefs**

```yaml
  - it: should support multiple backendRefs with weights for traffic splitting
    set:
      generic:
        ingressesGeneral:
          domain: "example.org"
        httpRoutesGeneral:
          parentRefs:
            - name: gw
              namespace: gw-ns
      httpRoutes:
        canary-app:
          hostnames:
            - subdomain: app
          rules:
            - matches:
                - path:
                    type: PathPrefix
                    value: /
              backendRefs:
                - name: app-stable
                  port: 8080
                  weight: 90
                - name: app-canary
                  port: 8080
                  weight: 10
    asserts:
      - equal:
          path: spec.rules[0].backendRefs[0].name
          value: app-stable
      - equal:
          path: spec.rules[0].backendRefs[0].weight
          value: 90
      - equal:
          path: spec.rules[0].backendRefs[1].name
          value: app-canary
      - equal:
          path: spec.rules[0].backendRefs[1].weight
          value: 10
```

- [ ] **Step 5: Add test for header and query param matches**

```yaml
  - it: should render header and queryParam matches
    set:
      generic:
        ingressesGeneral:
          domain: "example.org"
        httpRoutesGeneral:
          parentRefs:
            - name: gw
              namespace: gw-ns
      httpRoutes:
        my-app:
          hostnames:
            - subdomain: my-app
          rules:
            - matches:
                - path:
                    type: PathPrefix
                    value: /api
                  headers:
                    - name: x-env
                      value: staging
                      type: Exact
                  queryParams:
                    - name: version
                      value: "2"
              backendRefs:
                - name: my-app
                  port: 8080
    asserts:
      - equal:
          path: spec.rules[0].matches[0].headers[0].name
          value: x-env
      - equal:
          path: spec.rules[0].matches[0].headers[0].value
          value: "staging"
      - equal:
          path: spec.rules[0].matches[0].headers[0].type
          value: Exact
      - equal:
          path: spec.rules[0].matches[0].queryParams[0].name
          value: version
      - equal:
          path: spec.rules[0].matches[0].queryParams[0].value
          value: "2"
```

- [ ] **Step 6: Add test for merged labels**

```yaml
  - it: should merge global and resource labels
    set:
      generic:
        labels:
          global-label: "true"
        ingressesGeneral:
          domain: "example.org"
        httpRoutesGeneral:
          parentRefs:
            - name: gw
              namespace: gw-ns
      httpRoutes:
        my-app:
          labels:
            app-label: "custom"
          hostnames:
            - subdomain: my-app
          rules:
            - matches:
                - path:
                    type: PathPrefix
                    value: /
    asserts:
      - equal:
          path: metadata.labels.global-label
          value: "true"
      - equal:
          path: metadata.labels.app-label
          value: "custom"
```

- [ ] **Step 7: Run all tests**

Run: `helm unittest charts/ks-universal -f tests/httproute_test.yaml`
Expected: all PASS

- [ ] **Step 8: Commit**

```bash
git add charts/ks-universal/tests/httproute_test.yaml
git commit -m "test(httproute): add tests for parentRefs override, defaults, traffic splitting, matches, labels"
```

---

### Task 4: Add HTTPRoute validation

**Files:**
- Modify: `charts/ks-universal/templates/_validation.tpl:894` (add `validateHttpRoute` and wire into `validate`)

- [ ] **Step 1: Add `validateHttpRoute` helper**

Insert before the `validate` definition (before line 824 in `_validation.tpl`):

```gotemplate
{{/*
HTTPRoute validation
*/}}
{{- define "ks-universal.validateHttpRoute" -}}
  {{- $name := .name -}}
  {{- $config := .config -}}
  {{- $root := .root -}}
  {{- $generic := $root.Values.generic | default dict -}}
  {{- $httpRoutesGeneral := index $generic "httpRoutesGeneral" | default dict -}}
  {{- $ingressesGeneral := $generic.ingressesGeneral | default dict -}}
  {{- $globalDomain := $ingressesGeneral.domain | default "" | trim -}}

  {{- if not $config -}}
    {{ fail (printf "HTTPRoute %s: configuration must not be empty" $name) }}
  {{- end }}

  {{- /* parentRefs required: per-route or global */ -}}
  {{- if and (not $config.parentRefs) (not $httpRoutesGeneral.parentRefs) -}}
    {{ fail (printf "HTTPRoute %s: parentRefs must be specified either per-route or in generic.httpRoutesGeneral" $name) }}
  {{- end }}

  {{- /* hostnames required */ -}}
  {{- if not $config.hostnames -}}
    {{ fail (printf "HTTPRoute %s: hostnames is required" $name) }}
  {{- end }}

  {{- /* Validate each hostname */ -}}
  {{- range $hostname := $config.hostnames }}
    {{- $computedHost := include "ks-universal.computedIngressHost" (dict "host" $hostname.host "subdomain" $hostname.subdomain "globalDomain" $globalDomain) | trim }}
    {{- if not $computedHost }}
      {{ fail (printf "HTTPRoute %s: computed hostname is empty" $name) }}
    {{- end }}
  {{- end }}

  {{- /* rules required */ -}}
  {{- if not $config.rules -}}
    {{ fail (printf "HTTPRoute %s: at least one rule is required" $name) }}
  {{- end }}

  {{- /* Validate rules */ -}}
  {{- range $i, $rule := $config.rules }}
    {{- if not $rule.matches -}}
      {{ fail (printf "HTTPRoute %s: rule[%d] must have at least one match" $name $i) }}
    {{- end }}
    {{- range $j, $match := $rule.matches }}
      {{- if $match.path }}
        {{- if $match.path.type }}
          {{- $validTypes := list "PathPrefix" "Exact" "RegularExpression" }}
          {{- if not (has $match.path.type $validTypes) }}
            {{ fail (printf "HTTPRoute %s: rule[%d].match[%d].path.type must be PathPrefix, Exact, or RegularExpression, got '%s'" $name $i $j $match.path.type) }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- range $h, $header := $match.headers }}
        {{- if $header.type }}
          {{- $validHeaderTypes := list "Exact" "RegularExpression" }}
          {{- if not (has $header.type $validHeaderTypes) }}
            {{ fail (printf "HTTPRoute %s: rule[%d].match[%d].header[%d].type must be Exact or RegularExpression, got '%s'" $name $i $j $h $header.type) }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
```

- [ ] **Step 2: Wire `validateHttpRoute` into the `validate` function**

In `_validation.tpl`, inside the `ks-universal.validate` definition, add before the closing `{{- end -}}` (before line 895):

```gotemplate
{{/* HTTPRoutes validation */}}
{{- if $root.Values.httpRoutes -}}
{{- range $routeName, $routeConfig := $root.Values.httpRoutes -}}
{{- include "ks-universal.validateHttpRoute" (dict "name" $routeName "config" $routeConfig "root" $root) -}}
{{- end -}}
{{- end -}}
```

- [ ] **Step 3: Add validation tests**

Append to `charts/ks-universal/tests/httproute_test.yaml`:

```yaml
  - it: should fail when parentRefs missing everywhere
    set:
      generic:
        ingressesGeneral:
          domain: "example.org"
      httpRoutes:
        my-app:
          hostnames:
            - subdomain: my-app
          rules:
            - matches:
                - path:
                    type: PathPrefix
                    value: /
    asserts:
      - failedTemplate:
          errorMessage: "HTTPRoute my-app: parentRefs must be specified either per-route or in generic.httpRoutesGeneral"

  - it: should fail when hostnames empty
    set:
      generic:
        httpRoutesGeneral:
          parentRefs:
            - name: gw
              namespace: gw-ns
      httpRoutes:
        my-app:
          rules:
            - matches:
                - path:
                    type: PathPrefix
                    value: /
    asserts:
      - failedTemplate:
          errorMessage: "HTTPRoute my-app: hostnames is required"

  - it: should fail when invalid path type
    set:
      generic:
        ingressesGeneral:
          domain: "example.org"
        httpRoutesGeneral:
          parentRefs:
            - name: gw
              namespace: gw-ns
      httpRoutes:
        my-app:
          hostnames:
            - subdomain: my-app
          rules:
            - matches:
                - path:
                    type: Invalid
                    value: /
    asserts:
      - failedTemplate:
          errorMessage: "HTTPRoute my-app: rule[0].match[0].path.type must be PathPrefix, Exact, or RegularExpression"
```

- [ ] **Step 4: Run all tests (httproute + existing)**

Run: `helm unittest charts/ks-universal`
Expected: all PASS (both new and existing tests)

- [ ] **Step 5: Commit**

```bash
git add charts/ks-universal/templates/_validation.tpl charts/ks-universal/tests/httproute_test.yaml
git commit -m "feat(httproute): add HTTPRoute validation with unit tests"
```

---

### Task 5: Add `autoHttpRoute` helper and deployment integration

**Files:**
- Modify: `charts/ks-universal/templates/_helpers.tpl` (add `autoHttpRoute` after `autoIngress`)
- Modify: `charts/ks-universal/templates/deployment.yaml:107` (add conditional block)
- Create: `charts/ks-universal/tests/httproute_auto_create_test.yaml`

- [ ] **Step 1: Write test for auto-create from deployment**

Create `charts/ks-universal/tests/httproute_auto_create_test.yaml`:

```yaml
suite: test httproute auto create
templates:
  - deployment.yaml
tests:
  - it: should auto-create HTTPRoute from deployment
    set:
      generic:
        ingressesGeneral:
          domain: "example.org"
        httpRoutesGeneral:
          parentRefs:
            - name: shared-gateway
              namespace: gateway-system
      deployments:
        my-app:
          autoCreateHttpRoute: true
          containers:
            main:
              image: nginx
              imageTag: latest
              ports:
                http:
                  containerPort: 8080
                  servicePort: 8080
          httpRoute:
            hostnames:
              - subdomain: my-app
            rules:
              - matches:
                  - path:
                      type: PathPrefix
                      value: /
    asserts:
      - containsDocument:
          kind: HTTPRoute
          apiVersion: gateway.networking.k8s.io/v1
      - isKind:
          of: HTTPRoute
        documentIndex: 1
      - equal:
          path: metadata.name
          value: my-app
        documentIndex: 1
      - equal:
          path: spec.parentRefs[0].name
          value: shared-gateway
        documentIndex: 1
      - equal:
          path: spec.hostnames[0]
          value: my-app.example.org
        documentIndex: 1
      - equal:
          path: spec.rules[0].backendRefs[0].name
          value: my-app
        documentIndex: 1
      - equal:
          path: spec.rules[0].backendRefs[0].port
          value: 8080
        documentIndex: 1

  - it: should auto-populate backendRef from deployment container ports
    set:
      generic:
        ingressesGeneral:
          domain: "example.org"
        httpRoutesGeneral:
          parentRefs:
            - name: gw
              namespace: gw-ns
      deployments:
        api-svc:
          autoCreateHttpRoute: true
          containers:
            main:
              image: api
              imageTag: "1.0"
              ports:
                http:
                  containerPort: 3000
                  servicePort: 3000
          httpRoute:
            hostnames:
              - subdomain: api
            rules:
              - matches:
                  - path:
                      type: PathPrefix
                      value: /
    asserts:
      - equal:
          path: spec.rules[0].backendRefs[0].name
          value: api-svc
        documentIndex: 1
      - equal:
          path: spec.rules[0].backendRefs[0].port
          value: 3000
        documentIndex: 1

  - it: should default hostname to deployment name as subdomain when httpRoute.hostnames not specified
    set:
      generic:
        ingressesGeneral:
          domain: "example.org"
        httpRoutesGeneral:
          parentRefs:
            - name: gw
              namespace: gw-ns
      deployments:
        web-app:
          autoCreateHttpRoute: true
          containers:
            main:
              image: web
              imageTag: latest
              ports:
                http:
                  containerPort: 80
          httpRoute:
            rules:
              - matches:
                  - path:
                      type: PathPrefix
                      value: /
    asserts:
      - equal:
          path: spec.hostnames[0]
          value: web-app.example.org
        documentIndex: 1
```

- [ ] **Step 2: Run test to verify it fails**

Run: `helm unittest charts/ks-universal -f tests/httproute_auto_create_test.yaml`
Expected: FAIL

- [ ] **Step 3: Add `autoHttpRoute` helper to `_helpers.tpl`**

Insert after the `autoIngress` helper (after the `{{- end }}` that closes `autoIngress`, around line 533 in `_helpers.tpl`):

```gotemplate
{{/* Helper for auto-creating HTTPRoute from deployment */}}
{{- define "ks-universal.autoHttpRoute" -}}
{{- $deploymentName := .deploymentName -}}
{{- $deploymentConfig := .deploymentConfig -}}
{{- $root := .root -}}
{{- $generic := $root.Values.generic | default dict -}}
{{- $httpRoutesGeneral := index $generic "httpRoutesGeneral" | default dict -}}
{{- $ingressesGeneral := $generic.ingressesGeneral | default dict -}}
{{- $globalDomain := $ingressesGeneral.domain | default "" | trim -}}
{{- $httpRouteConfig := $deploymentConfig.httpRoute | default dict -}}

{{- /* Apply defaults */ -}}
{{- $defaultedRoute := include "ks-universal.httpRouteDefaults" (dict "httpRoute" $httpRouteConfig "general" $httpRoutesGeneral) | fromYaml -}}

{{- /* Collect ports from containers (same logic as autoIngress) */ -}}
{{- $ports := list -}}
{{- range $containerName, $container := $deploymentConfig.containers -}}
  {{- range $portName, $port := $container.ports -}}
    {{- $ports = append $ports (dict "name" $portName "port" $port.containerPort) -}}
  {{- end -}}
{{- end -}}
{{- $firstPort := first $ports -}}
{{- $backendPort := 80 -}}
{{- if $firstPort -}}
  {{- $backendPort = $firstPort.port -}}
{{- end -}}

{{- /* Resolve hostnames: use provided or default to deploymentName as subdomain */ -}}
{{- $hostnames := list -}}
{{- if $defaultedRoute.hostnames -}}
  {{- range $defaultedRoute.hostnames -}}
    {{- $hostnames = append $hostnames (include "ks-universal.computedIngressHost" (dict "host" .host "subdomain" .subdomain "globalDomain" $globalDomain) | trim) -}}
  {{- end -}}
{{- else -}}
  {{- $hostnames = append $hostnames (include "ks-universal.computedIngressHost" (dict "subdomain" $deploymentName "globalDomain" $globalDomain) | trim) -}}
{{- end -}}

apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ $deploymentName }}
  labels:
{{ include "ks-universal.labels" (dict "Chart" $root.Chart "Release" $root.Release "name" $deploymentName) | nindent 4 | trimPrefix "\n"}}
    {{- $extraLabels := include "ks-universal.mergeLabels" (dict "root" $root "resourceLabels" $httpRouteConfig.labels) }}
    {{- if $extraLabels }}
    {{- $extraLabels | nindent 4 }}
    {{- end }}
  {{- $mergedAnnotations := include "ks-universal.mergeAnnotations" (dict "root" $root "resourceAnnotations" $defaultedRoute.annotations) }}
  {{- if $mergedAnnotations }}
  annotations:
    {{- $mergedAnnotations | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- toYaml $defaultedRoute.parentRefs | nindent 4 }}
  hostnames:
    {{- range $hostnames }}
    - {{ . | quote }}
    {{- end }}
  rules:
    {{- range $rule := $defaultedRoute.rules }}
    - matches:
        {{- range $match := $rule.matches }}
        - path:
            type: {{ $match.path.type | default "PathPrefix" }}
            value: {{ $match.path.value | default "/" }}
          {{- if $match.headers }}
          headers:
            {{- range $header := $match.headers }}
            - name: {{ $header.name }}
              value: {{ $header.value | quote }}
              {{- if $header.type }}
              type: {{ $header.type }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if $match.queryParams }}
          queryParams:
            {{- range $qp := $match.queryParams }}
            - name: {{ $qp.name }}
              value: {{ $qp.value | quote }}
              {{- if $qp.type }}
              type: {{ $qp.type }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
      backendRefs:
        {{- if $rule.backendRefs }}
        {{- range $ref := $rule.backendRefs }}
        - name: {{ $ref.name | default $deploymentName }}
          port: {{ $ref.port | default $backendPort }}
          {{- if $ref.weight }}
          weight: {{ $ref.weight }}
          {{- end }}
        {{- end }}
        {{- else }}
        - name: {{ $deploymentName }}
          port: {{ $backendPort }}
        {{- end }}
    {{- end }}
{{- end }}
```

- [ ] **Step 4: Add auto-create block to `deployment.yaml`**

In `charts/ks-universal/templates/deployment.yaml`, after the `autoCreateIngress` block (after line 107), add:

```gotemplate
{{/* Auto-create HTTPRoute if enabled */}}
{{- if $deploymentConfig.autoCreateHttpRoute }}
{{- include "ks-universal.autoHttpRoute" (dict "deploymentName" $deploymentName "deploymentConfig" $deploymentConfig "root" $) }}
---
{{- end }}
```

- [ ] **Step 5: Run auto-create tests**

Run: `helm unittest charts/ks-universal -f tests/httproute_auto_create_test.yaml`
Expected: all PASS

- [ ] **Step 6: Run full test suite**

Run: `helm unittest charts/ks-universal`
Expected: all PASS (no regressions)

- [ ] **Step 7: Commit**

```bash
git add charts/ks-universal/templates/_helpers.tpl charts/ks-universal/templates/deployment.yaml charts/ks-universal/tests/httproute_auto_create_test.yaml
git commit -m "feat(httproute): add autoCreateHttpRoute support from deployments"
```

---

### Task 6: Final verification

**Files:** none (verification only)

- [ ] **Step 1: Run full test suite**

Run: `helm unittest charts/ks-universal`
Expected: all tests PASS, no regressions

- [ ] **Step 2: Test template rendering with a complete example**

Run:
```bash
helm template test-release charts/ks-universal --set-json '{
  "generic": {
    "ingressesGeneral": {"domain": "example.org"},
    "httpRoutesGeneral": {"parentRefs": [{"name": "gw", "namespace": "gw-ns"}]}
  },
  "httpRoutes": {
    "my-app": {
      "hostnames": [{"subdomain": "app"}],
      "rules": [{"matches": [{"path": {"type": "PathPrefix", "value": "/"}}], "backendRefs": [{"name": "my-app", "port": 8080}]}]
    }
  }
}'
```
Expected: valid HTTPRoute YAML rendered

- [ ] **Step 3: Verify no regressions on existing resources**

Run:
```bash
helm template test-release charts/ks-universal --set-json '{
  "generic": {"ingressesGeneral": {"domain": "example.org", "ingressClassName": "nginx"}},
  "deployments": {
    "test": {
      "autoCreateIngress": true,
      "autoCreateService": true,
      "containers": {"main": {"image": "nginx", "imageTag": "latest", "ports": {"http": {"containerPort": 80, "servicePort": 80}}}},
      "ingress": {"hosts": [{"subdomain": "test", "paths": [{"path": "/", "pathType": "Prefix"}]}]}
    }
  }
}'
```
Expected: Deployment + Service + Ingress rendered, no HTTPRoute (not enabled)

- [ ] **Step 4: Commit snapshot updates if any**

```bash
git add -A && git status
# If snapshot files changed:
git commit -m "test: update snapshots for HTTPRoute support"
```
