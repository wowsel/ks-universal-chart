# HTTPRoute (Gateway API) Support for ks-universal

## Summary

Add Gateway API HTTPRoute support to the ks-universal Helm chart. HTTPRoute is the stable (v1) Gateway API resource for HTTP routing — a modern alternative to Ingress. Implementation follows the existing Ingress pattern: standalone `httpRoutes:` map in values, global defaults via `httpRoutesGeneral`, and `autoCreateHttpRoute` from deployments.

## Scope

**In scope:**
- Standalone `httpRoutes:` resource definition
- Global defaults via `generic.httpRoutesGeneral`
- Auto-create HTTPRoute from deployments (`autoCreateHttpRoute`)
- Path, header, and query param matching
- Multiple backendRefs with weights (traffic splitting)
- Hostname computation via existing `computedIngressHost` helper
- Validation and unit tests

**Out of scope:**
- Gateway resource management (platform team responsibility)
- TLS configuration (handled at Gateway listener level)
- DexAuthenticator integration
- Certificate auto-creation
- Filters (RequestHeaderModifier, URLRewrite, RequestMirror) — future iteration
- Other route types (GRPCRoute, TLSRoute, TCPRoute, UDPRoute) — future iteration

## Values Structure

### Standalone HTTPRoutes

```yaml
httpRoutes:
  my-app:
    parentRefs:                    # optional, overrides global
      - name: my-gateway
        namespace: gateway-ns
        sectionName: https         # optional
    hostnames:
      - host: app.example.com      # full domain
      # OR
      - subdomain: app             # subdomain + globalDomain
    rules:
      - matches:
          - path:
              type: PathPrefix     # PathPrefix | Exact | RegularExpression
              value: /api
            headers:               # optional
              - name: x-env
                value: staging
                type: Exact        # Exact | RegularExpression
            queryParams:           # optional
              - name: version
                value: "2"
        backendRefs:
          - name: my-app           # default = httproute name
            port: 8080             # default = 80
            weight: 100            # default = 1
    labels: {}
    annotations: {}
```

### Global Defaults

```yaml
generic:
  httpRoutesGeneral:
    parentRefs:
      - name: shared-gateway
        namespace: gateway-system
    annotations: {}
    labels: {}
  # httpRoutesGeneral does NOT have its own domain field.
  # Hostname resolution reuses generic.ingressesGeneral.domain as globalDomain.
  ingressesGeneral:
    domain: example.com    # shared by both Ingress and HTTPRoute hostnames
```

### Auto-create from Deployments

```yaml
deployments:
  my-app:
    autoCreateHttpRoute: true
    httpRoute:
      hostnames:
        - subdomain: my-app
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          # backendRefs auto-populated: name = deployment name, port from container
```

## Template Design

### New file: `templates/httproute.yaml`

Iterates over `httpRoutes` map following the same pattern as `ingress.yaml`:

- `apiVersion: gateway.networking.k8s.io/v1`
- `kind: HTTPRoute`
- Metadata: name, merged labels via `ks-universal.labels` + `mergeLabels`, merged annotations via `mergeAnnotations`
- `spec.parentRefs`: from route config, fallback to `httpRoutesGeneral.parentRefs`
- `spec.hostnames`: the chart's input format (`hostnames[].host` / `hostnames[].subdomain`) is transformed to Gateway API's flat string array via `computedIngressHost`. Each element is resolved to a full hostname string.
- `spec.rules`: rendered from values with matches and backendRefs

### New helpers in `_helpers.tpl`

**`ks-universal.httpRouteDefaults`** — merges global defaults into per-route config:
- parentRefs (route-level fully replaces global, not a merge)
- annotations (merge, resource-level wins)
- labels (merge, resource-level wins)

Simpler than `ingressDefaults` — no TLS, no ingressClassName.

**`ks-universal.autoHttpRoute`** — generates HTTPRoute from deployment config:
- Called from `deployment.yaml` via a new conditional block (same pattern as existing `autoCreateIngress` block) when `autoCreateHttpRoute: true`
- BackendRef name = deployment name
- BackendRef port = first port from first container (same logic as autoIngress: collects all ports across containers, takes first). Falls back to 80 if no ports defined.
- Hostnames from `httpRoute.hostnames`, or deployment name as subdomain + globalDomain

### Additions to `_validation.tpl`

- parentRefs required: must be present either per-route or globally
- hostnames: at least one hostname required
- rules: at least one rule, backendRefs non-empty per rule
- path.type: must be PathPrefix, Exact, or RegularExpression
- header match type: must be Exact or RegularExpression

### Reused without changes

- `computedIngressHost` — hostname resolution logic identical for Ingress and HTTPRoute
- `mergeLabels`, `mergeAnnotations` — standard merge helpers
- `ks-universal.labels` — standard label generation

## Default Behaviors

- `backendRefs` not specified in rule: auto `name: <httproute-name>`, `port: 80`
- Single backendRef without `name`: inherits httproute name
- `weight` omitted: defaults to 1 (Kubernetes default)
- `hostnames` not specified but `ingressesGeneral.domain` exists: uses globalDomain (shared with Ingress)
- Auto-create without explicit `httpRoute.hostnames`: deployment name as subdomain + globalDomain

## Tests

Unit tests via helm-unittest in `httproute_test.yaml`:

- Standalone HTTPRoute renders correctly with full config
- Global defaults from `httpRoutesGeneral` are applied
- Per-route `parentRefs` overrides global
- `computedIngressHost` works for hostnames (host and subdomain variants)
- Multiple matches and backendRefs with weights
- Auto-create from deployment: correct backendRef (name + port)
- Defaults: backendRef name = httproute name, port = 80
- Merged labels and annotations
- Validation error when parentRefs missing everywhere
- Validation error when hostnames empty
