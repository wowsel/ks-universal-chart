# _helpers.tpl
{{/*
Expand the name of the chart.
*/}}
{{- define "ks-universal.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
For tests, always use a fixed version to avoid snapshot failures when chart version changes.
In production, use the actual chart version.
*/}}
{{- define "ks-universal.chart" -}}
{{- if eq (default "" .Release.Name) "RELEASE-NAME" -}}
{{/* This is a test environment, use fixed version */}}
{{- printf "%s-test-version" .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- else -}}
{{/* This is a production environment, use actual version */}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end }}

{{/*
Create chart name with stable version for tests
*/}}
{{- define "ks-universal.chart.test" -}}
{{- if .Release.IsUpgrade | default false -}}
{{- printf "%s-testing" .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "ks-universal.chart" . -}}
{{- end -}}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ks-universal.labels" -}}
helm.sh/chart: {{ include "ks-universal.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .name }}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ .name }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ks-universal.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ks-universal.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "ks-universal.componentLabels" -}}
{{- $name := .name -}}
{{- $instance := .root.Release.Name -}}
app.kubernetes.io/name: {{ $name }}
app.kubernetes.io/instance: {{ $instance }}
app.kubernetes.io/component: {{ $name }}
{{- end }}

{{/*
Create the deployment selector labels
*/}}
{{- define "ks-universal.deploymentSelector" -}}
{{- $name := .name -}}
{{- $instance := .instance -}}
app.kubernetes.io/name: {{ $name }}
app.kubernetes.io/instance: {{ $instance }}
app.kubernetes.io/component: {{ $name }}
{{- end }}


{{/*
Service labels
*/}}
{{- define "ks-universal.serviceLabels" -}}
{{- $serviceName := .serviceName -}}
{{- $root := .root -}}
{{- include "ks-universal.labels" (dict "Chart" $root.Chart "Release" $root.Release "name" $serviceName) | nindent 0 }}
{{- end }}

{{/* Helper for deployment defaults */}}
{{- define "ks-universal.deploymentDefaults" -}}
{{- $deployment := .deployment }}
{{- $general := .general }}
{{- $result := deepCopy $deployment }}
{{- if $general }}
  {{- if $general.securityContext }}
    {{- $result = merge $result (dict "securityContext" $general.securityContext) }}
  {{- end }}
  {{- if $general.nodeSelector }}
    {{- $result = merge $result (dict "nodeSelector" $general.nodeSelector) }}
  {{- end }}
  {{- if $general.tolerations }}
    {{- $result = merge $result (dict "tolerations" $general.tolerations) }}
  {{- end }}
  {{- if $general.affinity }}
    {{- $result = merge $result (dict "affinity" $general.affinity) }}
  {{- end }}
  {{- if $general.probes }}
    {{- range $containerName, $container := $result.containers }}
      {{- if not $container.probes }}
        {{- $_ := set $container "probes" $general.probes }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if $general.strategy }}
    {{- if not $result.strategy }}
      {{- $result = merge $result (dict "strategy" $general.strategy) }}
    {{- end }}
  {{- end }}
  {{- if $general.parallelism }}
    {{- if not $result.parallelism }}
      {{- $result = merge $result (dict "parallelism" (int $general.parallelism)) }}
    {{- end }}
  {{- end }}
  {{- if $general.completions }}
    {{- if not $result.completions }}
      {{- $result = merge $result (dict "completions" (int $general.completions)) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- toYaml $result }}
{{- end }}

{{- define "ks-universal.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "ks-universal.configName" -}}
{{- printf "%s" .name }}
{{- end }}

{{- define "ks-universal.ingressDefaults" -}}
  {{- $ingress := .ingress | default dict }}
  {{- $general := .general | default dict }}
  {{- $result := deepCopy $ingress }}

  {{- /* Наследование общих аннотаций, ingressClassName и tls */ -}}
  {{- if $general.annotations }}
    {{- $result = merge $result (dict "annotations" (merge (default dict $ingress.annotations) $general.annotations)) }}
  {{- end }}
  {{- if $general.ingressClassName }}
    {{- if not $ingress.ingressClassName }}
      {{- $result = merge $result (dict "ingressClassName" $general.ingressClassName) }}
    {{- end }}
  {{- end }}
  {{- if $general.tls }}
    {{- if not $ingress.tls }}
      {{- $result = merge $result (dict "tls" $general.tls) }}
    {{- end }}
  {{- end }}

  {{- /* Новый функционал: обработка глобального домена и subdomain */ -}}
  {{- $globalDomain := $general.domain | default "" }}
  {{- if and $globalDomain (hasKey $result "hosts") }}
    {{- $newHosts := list }}
    {{- range $index, $hostEntry := $result.hosts }}
      {{- $newHost := $hostEntry }}
      {{- if not (hasKey $hostEntry "host") }}
        {{- if hasKey $hostEntry "subdomain" }}
          {{- /* Формируем host как subdomain + "." + globalDomain */ -}}
          {{- $newHost = merge $hostEntry (dict "host" (printf "%s.%s" $hostEntry.subdomain $globalDomain)) }}
        {{- end }}
      {{- end }}
      {{- $newHosts = append $newHosts $newHost }}
    {{- end }}
    {{- $_ := set $result "hosts" $newHosts }}
  {{- end }}

  {{- toYaml $result }}
{{- end }}

{{- define "ks-universal.hasMetricsPort" -}}
{{- $containers := .containers }}
{{- $hasMetricsPort := false }}
{{- range $containerName, $container := $containers }}
  {{- if $container.ports }}
    {{- range $portName, $port := $container.ports }}
      {{- if eq $portName "http-metrics" }}
        {{- $hasMetricsPort = true }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $hasMetricsPort }}
{{- end }}

{{- define "ks-universal.shouldCreateServiceMonitor" -}}
{{- $deploymentConfig := .deploymentConfig }}
{{- $generalConfig := .general }}
{{- $result := false }}
{{/* Проверяем сначала локальное значение */}}
{{- if hasKey $deploymentConfig "autoCreateServiceMonitor" }}
    {{- $result = $deploymentConfig.autoCreateServiceMonitor }}
{{- else if hasKey $generalConfig "autoCreateServiceMonitor" }}
    {{- $result = $generalConfig.autoCreateServiceMonitor }}
{{- else }}
    {{- $result = false }}
{{- end }}
{{- $result | toString }}
{{- end }}

{{/* Helper для создания soft anti-affinity */}}
{{- define "ks-universal.softAntiAffinity" -}}
{{- $deploymentName := .deploymentName }}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchLabels:
          app.kubernetes.io/component: {{ $deploymentName }}
      topologyKey: kubernetes.io/hostname
{{- end }}

{{/* Helper для обработки affinity настроек */}}
{{- define "ks-universal.processAffinity" -}}
{{- $config := .config }}
{{- $deploymentName := .deploymentName }}
{{- $general := .general }}
{{- $result := dict }}

{{/* Проверяем нужно ли создавать soft anti-affinity */}}
{{- $createSoftAntiAffinity := false }}
{{- if hasKey $config "autoCreateSoftAntiAffinity" }}
    {{- $createSoftAntiAffinity = $config.autoCreateSoftAntiAffinity }}
{{- else if and $general (hasKey $general "autoCreateSoftAntiAffinity") }}
    {{- $createSoftAntiAffinity = $general.autoCreateSoftAntiAffinity }}
{{- end }}

{{/* Собираем все nodeSelector'ы в один список для конвертации в nodeAffinity */}}
{{- $nodeSelectors := list }}

{{/* Если задан affinity в конфиге - используем его как базу */}}
{{- if $config.affinity }}
    {{- $result = deepCopy $config.affinity }}
{{- end }}

{{/* Если есть nodeSelector в конфиге - добавляем его в список для конвертации */}}
{{- if $config.nodeSelector }}
    {{- range $key, $value := $config.nodeSelector }}
        {{- $nodeSelectors = append $nodeSelectors (dict "key" $key "operator" "In" "values" (list $value)) }}
    {{- end }}
{{- end }}

{{/* Если есть nodeSelector в general настройках и он не переопределен в конфиге - добавляем его */}}
{{- if and $general.nodeSelector (not $config.nodeSelector) }}
    {{- range $key, $value := $general.nodeSelector }}
        {{- $nodeSelectors = append $nodeSelectors (dict "key" $key "operator" "In" "values" (list $value)) }}
    {{- end }}
{{- end }}

{{/* Если у нас есть nodeSelector'ы для конвертации */}}
{{- if $nodeSelectors }}
    {{/* Если уже есть nodeAffinity - добавляем новые термы */}}
    {{- if hasKey $result "nodeAffinity" }}
        {{- if hasKey $result.nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution" }}
            {{- $nodeSelectorTerms := $result.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms }}
            {{/* Добавляем наши новые термы к существующим */}}
            {{- $newTerm := dict "matchExpressions" $nodeSelectors }}
            {{- $nodeSelectorTerms = append $nodeSelectorTerms $newTerm }}
            {{- $_ := set $result.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution "nodeSelectorTerms" $nodeSelectorTerms }}
        {{- else }}
            {{- $_ := set $result.nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution" (dict "nodeSelectorTerms" (list (dict "matchExpressions" $nodeSelectors))) }}
        {{- end }}
    {{- else }}
        {{/* Создаем новый nodeAffinity */}}
        {{- $nodeAffinity := dict "requiredDuringSchedulingIgnoredDuringExecution" (dict "nodeSelectorTerms" (list (dict "matchExpressions" $nodeSelectors))) }}
        {{- $_ := set $result "nodeAffinity" $nodeAffinity }}
    {{- end }}
{{- end }}

{{/* Если нужно создать soft anti-affinity и еще нет podAntiAffinity */}}
{{- if and $createSoftAntiAffinity (not (hasKey $result "podAntiAffinity")) }}
    {{- $antiAffinity := dict "preferredDuringSchedulingIgnoredDuringExecution" (list (dict "weight" 100 "podAffinityTerm" (dict "labelSelector" (dict "matchLabels" (dict "app.kubernetes.io/component" $deploymentName)) "topologyKey" "kubernetes.io/hostname"))) }}
    {{- $_ := set $result "podAntiAffinity" $antiAffinity }}
{{- end }}

{{- toYaml $result }}
{{- end }}

{{/* Helper для обработки dynamic values */}}
{{- define "ks-universal.tplValue" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end }}

{{/* Helper for generating containers */}}
{{- define "ks-universal.containers" -}}
{{- $root := .root -}}
{{- $containers := .containers -}}
{{- range $containerName, $container := $containers }}
- {{ include "ks-universal.container" (dict "containerName" $containerName "container" $container "root" $root) | nindent 2 | trim }}
{{- end }}
{{- end }}

{{/* Helper for generating container */}}
{{- define "ks-universal.container" -}}
{{- $containerName := .containerName -}}
{{- $container := .container -}}
{{- $root := .root -}}
name: {{ $containerName }}
image: {{ include "ks-universal.tplValue" (dict "value" $container.image "context" $root) }}:{{ include "ks-universal.tplValue" (dict "value" $container.imageTag "context" $root) }}
{{- if $container.args }}
args:
  {{- toYaml $container.args | nindent 2 }}
{{- end }}
{{- if $container.command }}
command:
  {{- toYaml $container.command | nindent 2 }}
{{- end }}
{{- if $container.ports }}
ports:
  {{- range $portName, $port := $container.ports }}
  - name: {{ $portName }}
    containerPort: {{ $port.containerPort }}
    protocol: {{ $port.protocol | default "TCP" }}
  {{- end }}
{{- end }}
{{- if $container.volumeMounts }}
volumeMounts:
  {{- range $container.volumeMounts }}
  - name: {{ .name }}
    mountPath: {{ .mountPath }}
    {{- if .subPath }}
    subPath: {{ .subPath }}
    {{- end }}
    {{- if .readOnly }}
    readOnly: {{ .readOnly }}
    {{- end }}
  {{- end }}
{{- end -}}
{{/* Process environment variables */}}
{{- $envVars := list -}}
{{/* Add regular env vars if they exist */}}
{{- if $container.env -}}
  {{- range $container.env -}}
    {{- $envVars = append $envVars . -}}
  {{- end -}}
{{- end -}}
{{/* Process secretRefs if they exist */}}
{{- if and $container.secretRefs $root.Values.secretRefs -}}
  {{- range $refName := $container.secretRefs -}}
    {{- if hasKey $root.Values.secretRefs $refName -}}
      {{- range $env := index $root.Values.secretRefs $refName -}}
        {{- $envVars = append $envVars $env -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Output all environment variables */}}
{{- if $envVars }}
env:
  {{- range $envVars }}
  - name: {{ .name }}
    {{- if .value }}
    value: {{ include "ks-universal.tplValue" (dict "value" .value "context" $root) | quote }}
    {{- else if .valueFrom }}
    valueFrom:
      {{- toYaml .valueFrom | nindent 6 }}
    {{- else if .secretKeyRef }}
    valueFrom:
      secretKeyRef:
        name: {{ .secretKeyRef.name }}
        key: {{ .secretKeyRef.key }}
    {{- end }}
  {{- end }}
{{- end }}

{{- if $container.envFrom }}
envFrom:
  {{- range $container.envFrom }}
  - {{ .type }}Ref:
      name: {{ include "ks-universal.configName" (dict "root" $root "name" .configName) }}
  {{- end }}
{{- end }}
{{- with $container.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if $container.securityContext }}
securityContext:
  {{- toYaml $container.securityContext | nindent 2 }}
{{- end }}
{{- if $container.probes }}
{{- if $container.probes.livenessProbe }}
livenessProbe:
  {{- toYaml $container.probes.livenessProbe | nindent 2 }}
{{- end }}
{{- if $container.probes.readinessProbe }}
readinessProbe:
  {{- toYaml $container.probes.readinessProbe | nindent 2 }}
{{- end }}
{{- if $container.probes.startupProbe }}
startupProbe:
  {{- toYaml $container.probes.startupProbe | nindent 2 }}
{{- end }}
{{- end }}
{{- with $container.lifecycle }}
lifecycle:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/* Helper for generating DexAuthenticator annotations */}}
{{- define "ks-universal.dexAnnotations" -}}
{{- $root := .root -}}
{{- $namespace := .namespace | default $root.Release.Namespace -}}

{{/* Get global DexAuthenticator namespace and name if configured */}}
{{- $authName := "" -}}
{{- if and $root.Values.generic $root.Values.generic.dexAuthenticatorGeneral -}}
  {{- $namespace = $root.Values.generic.dexAuthenticatorGeneral.namespace | default $root.Release.Namespace -}}
  {{- $authName = $root.Values.generic.dexAuthenticatorGeneral.name | default (include "ks-universal.name" $root) -}}
{{- else -}}
  {{- $authName = include "ks-universal.name" $root -}}
{{- end -}}

nginx.ingress.kubernetes.io/auth-signin: https://$host/dex-authenticator/sign_in
nginx.ingress.kubernetes.io/auth-response-headers: X-Auth-Request-User,X-Auth-Request-Email
nginx.ingress.kubernetes.io/auth-url: https://{{ $authName }}-dex-authenticator.{{ $namespace }}.svc.cluster.local/dex-authenticator/auth
{{- end }}

{{/* Helper для автоматического создания ingress */}}
{{- define "ks-universal.autoIngress" -}}
{{- /* Подготовка переменных */ -}}
{{- $deploymentName := .deploymentName -}}
{{- $deploymentConfig := .deploymentConfig -}}
{{- $root := .root -}}
{{- $generic := $root.Values.generic | default dict -}}
{{- $ingressesGeneral := $generic.ingressesGeneral | default dict -}}
{{- $globalDomain := $ingressesGeneral.domain | default "" | trim -}}
{{- /* Применяем наследование для ingress */ -}}
{{- $defaultedIngress := include "ks-universal.ingressDefaults" (dict "ingress" ($deploymentConfig.ingress | default dict) "general" $root.Values.generic.ingressesGeneral) | fromYaml -}}
{{- /* Собираем список портов из контейнеров */ -}}
{{- $ports := list -}}
{{- range $containerName, $container := $deploymentConfig.containers -}}
  {{- range $portName, $port := $container.ports -}}
    {{- $ports = append $ports (dict "name" $portName "port" $port.containerPort) -}}
  {{- end -}}
{{- end -}}
{{- $firstPort := first $ports -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $deploymentName }}
  labels:
{{ include "ks-universal.labels" (dict "Chart" $root.Chart "Release" $root.Release "name" $deploymentName) | nindent 4 | trimPrefix "\n"}}
  annotations:
{{- with $defaultedIngress.annotations }}
{{ toYaml . | nindent 4 | trimPrefix "\n"}}
{{- end }}
{{- if $deploymentConfig.autoCreateCertificate }}
{{- if and $deploymentConfig.certificate $deploymentConfig.certificate.clusterIssuer }}
    cert-manager.io/cluster-issuer: {{ $deploymentConfig.certificate.clusterIssuer | quote }}
{{- else if and $deploymentConfig.certificate $deploymentConfig.certificate.issuer }}
    cert-manager.io/issuer: {{ $deploymentConfig.certificate.issuer | quote }}
{{- else }}
    cert-manager.io/cluster-issuer: "letsencrypt"
{{- end }}
{{- end }}
{{- /* Add DexAuthenticator annotations if enabled */ -}}
{{- if and $deploymentConfig.ingress.dexAuthenticator $deploymentConfig.ingress.dexAuthenticator.enabled }}
    {{ include "ks-universal.dexAnnotations" (dict "root" $root "namespace" ($deploymentConfig.namespace | default $root.Release.Namespace)) | nindent 4 }}
{{- end }}
spec:
{{- if $defaultedIngress.ingressClassName }}
  ingressClassName: {{ $defaultedIngress.ingressClassName }}
{{- end }}
{{- if or $defaultedIngress.tls $deploymentConfig.autoCreateCertificate }}
  tls:
{{- if $deploymentConfig.autoCreateCertificate }}
    - secretName: {{ printf "%s-tls" $deploymentName }}
      hosts:
{{- range $hostEntry := $defaultedIngress.hosts }}
        - {{ include "ks-universal.computedIngressHost" (dict "host" $hostEntry.host "subdomain" $hostEntry.subdomain "globalDomain" $globalDomain) | trim }}
{{- end }}
{{- else }}
{{ toYaml $defaultedIngress.tls | nindent 2 }}
{{- end }}
{{- end }}
  rules:
{{- range $hostEntry := $defaultedIngress.hosts }}
    - host: {{ include "ks-universal.computedIngressHost" (dict "host" $hostEntry.host "subdomain" $hostEntry.subdomain "globalDomain" $globalDomain) | trim }}
      http:
        paths:
{{- range $path := $hostEntry.paths }}
          - path: {{ $path.path }}
            pathType: {{ $path.pathType | default "Prefix" }}
            backend:
              service:
                name: {{ $deploymentName }}
                port:
{{- if $path.port }}
                  number: {{ $path.port }}
{{- else if $path.portName }}
                  name: {{ $path.portName }}
{{- else if $firstPort }}
{{- if $firstPort.name }}
                  name: {{ $firstPort.name }}
{{- else }}
                  number: {{ $firstPort.port }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/* Helper для автоматического создания PDB */}}
{{- define "ks-universal.autoPdb" -}}
{{- $deploymentName := .deploymentName }}
{{- $deploymentConfig := .deploymentConfig }}
{{- $root := .root }}

apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ $deploymentName }}
  labels:
    {{- include "ks-universal.labels" (dict "Chart" $root.Chart "Release" $root.Release "name" $deploymentName) | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "ks-universal.deploymentSelector" (dict "name" $deploymentName "instance" $root.Release.Name) | nindent 6 }}
  {{- if $deploymentConfig.pdbConfig }}
    {{- if $deploymentConfig.pdbConfig.minAvailable }}
  minAvailable: {{ $deploymentConfig.pdbConfig.minAvailable }}
    {{- end }}
    {{- if $deploymentConfig.pdbConfig.maxUnavailable }}
  maxUnavailable: {{ $deploymentConfig.pdbConfig.maxUnavailable }}
    {{- end }}
  {{- else }}
  maxUnavailable: 1
  {{- end }}
{{- end }}

{{/* Updated ServiceMonitor template with global settings */}}
{{- define "ks-universal.serviceMonitor" -}}
{{- $deploymentName := .deploymentName }}
{{- $deploymentConfig := .deploymentConfig }}
{{- $root := .root }}

{{/* Determine the port to monitor */}}
{{- $metricsPort := "" -}}
{{/* First try to find http-metrics port */}}
{{- range $containerName, $container := $deploymentConfig.containers -}}
  {{- range $portName, $port := $container.ports -}}
    {{- if eq $portName "http-metrics" -}}
      {{- $metricsPort = $portName -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{/* If http-metrics not found, use first available port */}}
{{- if not $metricsPort -}}
  {{- range $containerName, $container := $deploymentConfig.containers -}}
    {{- range $portName, $port := $container.ports -}}
      {{- if not $metricsPort -}}
        {{- $metricsPort = $portName -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Get general settings */}}
{{- $generalSettings := dict }}
{{- if and $root.Values.generic $root.Values.generic.serviceMonitorGeneral }}
  {{- $generalSettings = $root.Values.generic.serviceMonitorGeneral }}
{{- end }}

{{/* Merge labels from general and local configs */}}
{{- $labels := dict }}
{{/* First add general labels if they exist */}}
{{- if $generalSettings.labels }}
  {{- $labels = merge $labels $generalSettings.labels }}
{{- end }}
{{/* Then add local labels if they exist (they will override general ones) */}}
{{- if and $deploymentConfig.serviceMonitor $deploymentConfig.serviceMonitor.labels }}
  {{- $labels = merge $labels $deploymentConfig.serviceMonitor.labels }}
{{- end }}

apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ $deploymentName }}
  labels:
    {{- include "ks-universal.labels" (dict "Chart" $root.Chart "Release" $root.Release "name" $deploymentName) | nindent 4 }}
    {{- if $labels }}
    {{- toYaml $labels | nindent 4 }}
    {{- end }}
spec:
  selector:
    matchLabels:
      {{- include "ks-universal.componentLabels" (dict "name" $deploymentName "root" $root) | nindent 6 }}
  endpoints:
  {{- if and $deploymentConfig.serviceMonitor $deploymentConfig.serviceMonitor.endpoints }}
  {{- range $deploymentConfig.serviceMonitor.endpoints }}
  - port: {{ .port | default $metricsPort }}
    {{- if .path }}
    path: {{ .path }}
    {{- end }}
    {{- /* Use local interval if set, otherwise use general interval if available */}}
    {{- if .interval }}
    interval: {{ .interval }}
    {{- else if $generalSettings.interval }}
    interval: {{ $generalSettings.interval }}
    {{- end }}
    {{- /* Use local scrapeTimeout if set, otherwise use general scrapeTimeout if available */}}
    {{- if .scrapeTimeout }}
    scrapeTimeout: {{ .scrapeTimeout }}
    {{- else if $generalSettings.scrapeTimeout }}
    scrapeTimeout: {{ $generalSettings.scrapeTimeout }}
    {{- end }}
    {{- if .relabelings }}
    relabelings:
      {{- toYaml .relabelings | nindent 6 }}
    {{- end }}
    {{- if .metricRelabelings }}
    metricRelabelings:
      {{- toYaml .metricRelabelings | nindent 6 }}
    {{- end }}
    {{- if .honorLabels }}
    honorLabels: {{ .honorLabels }}
    {{- end }}
    {{- if .honorTimestamps }}
    honorTimestamps: {{ .honorTimestamps }}
    {{- end }}
    {{- if .scheme }}
    scheme: {{ .scheme }}
    {{- end }}
    {{- if .tlsConfig }}
    tlsConfig:
      {{- toYaml .tlsConfig | nindent 6 }}
    {{- end }}
  {{- end }}
  {{- else }}
  - port: {{ $metricsPort }}
    {{- if $deploymentConfig.serviceMonitor }}
    {{- with $deploymentConfig.serviceMonitor.path }}
    path: {{ . }}
    {{- end }}
    {{- /* For simple configuration, use local interval if set, otherwise use general interval */}}
    {{- if and $deploymentConfig.serviceMonitor $deploymentConfig.serviceMonitor.interval }}
    interval: {{ $deploymentConfig.serviceMonitor.interval }}
    {{- else if $generalSettings.interval }}
    interval: {{ $generalSettings.interval }}
    {{- end }}
    {{- /* For simple configuration, use local scrapeTimeout if set, otherwise use general scrapeTimeout */}}
    {{- if and $deploymentConfig.serviceMonitor $deploymentConfig.serviceMonitor.scrapeTimeout }}
    scrapeTimeout: {{ $deploymentConfig.serviceMonitor.scrapeTimeout }}
    {{- else if $generalSettings.scrapeTimeout }}
    scrapeTimeout: {{ $generalSettings.scrapeTimeout }}
    {{- end }}
    {{- with $deploymentConfig.serviceMonitor.relabelings }}
    relabelings:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with $deploymentConfig.serviceMonitor.metricRelabelings }}
    metricRelabelings:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- end }}
  {{- end }}
  {{- if and $deploymentConfig.serviceMonitor $deploymentConfig.serviceMonitor.namespaceSelector }}
  namespaceSelector:
    {{- toYaml $deploymentConfig.serviceMonitor.namespaceSelector | nindent 4 }}
  {{- end }}
{{- end }}

{{/* Helper для автоматического создания certificate */}}
{{- define "ks-universal.autoCertificate" -}}
{{- $deploymentName := .deploymentName -}}
{{- $deploymentConfig := .deploymentConfig -}}
{{- $root := .root -}}
{{- $generic := $root.Values.generic | default dict -}}
{{- $ingressesGeneral := $generic.ingressesGeneral | default dict -}}
{{- $globalDomain := $ingressesGeneral.domain | default "" | trim -}}
{{- /* Применяем наследование для ingress */ -}}
{{- $defaultedIngress := include "ks-universal.ingressDefaults" (dict "ingress" ($deploymentConfig.ingress | default dict) "general" $root.Values.generic.ingressesGeneral) | fromYaml -}}
{{- /* Собираем список доменов с использованием computedIngressHost */ -}}
{{- $domains := list -}}
{{- range $hostEntry := $defaultedIngress.hosts -}}
  {{- $computed := include "ks-universal.computedIngressHost" (dict "host" $hostEntry.host "subdomain" $hostEntry.subdomain "globalDomain" $globalDomain) | trim -}}
  {{- $domains = append $domains $computed -}}
{{- end -}}
{{- $certificateConfig := dict -}}
{{- if $deploymentConfig.certificate -}}
  {{- $certificateConfig = $deploymentConfig.certificate -}}
{{- end -}}
{{- $_ := set $certificateConfig "domains" $domains -}}

{{ include "ks-universal.certificate" (dict "certificateName" $deploymentName "certificateConfig" $certificateConfig "root" $root) -}}
{{- end }}


{{/* Helper for processing secretRefs */}}
{{- define "ks-universal.processSecretRefs" -}}
{{- $container := .container -}}
{{- $root := .root -}}
{{- $result := list -}}

{{- if and $container.secretRefs $root.Values.secretRefs -}}
  {{- range $container.secretRefs -}}
    {{- $refName := . -}}
    {{- if hasKey $root.Values.secretRefs $refName -}}
      {{- range $env := index $root.Values.secretRefs $refName -}}
        {{- $result = append $result $env -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- toYaml $result -}}
{{- end -}}