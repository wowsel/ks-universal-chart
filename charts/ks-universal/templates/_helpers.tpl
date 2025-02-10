# _helpers.tpl
{{/*
Expand the name of the chart.
*/}}
{{- define "ks-universal.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ks-universal.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
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
{{- $ingress := .ingress }}
{{- $general := .general }}
{{- $result := deepCopy $ingress }}
{{- if $general }}
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
    value: {{ .value | quote }}
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

{{/* Helper для автоматического создания ingress */}}
{{- define "ks-universal.autoIngress" -}}
{{- $deploymentName := .deploymentName }}
{{- $deploymentConfig := .deploymentConfig }}
{{- $root := .root }}
{{- $defaultedIngress := include "ks-universal.ingressDefaults" (dict "ingress" ($deploymentConfig.ingress | default dict) "general" $root.Values.ingressesGeneral) | fromYaml }}

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $deploymentName }}
  labels:
    {{- include "ks-universal.labels" (dict "Chart" $root.Chart "Release" $root.Release "name" $deploymentName) | nindent 4 }}
  annotations:
    {{- with $defaultedIngress.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- if $deploymentConfig.autoCreateCertificate }}
    {{- if and $deploymentConfig.certificate $deploymentConfig.certificate.clusterIssuer }}
    cert-manager.io/cluster-issuer: {{ $deploymentConfig.certificate.clusterIssuer }}
    {{- else if and $deploymentConfig.certificate $deploymentConfig.certificate.issuer }}
    cert-manager.io/issuer: {{ $deploymentConfig.certificate.issuer }}
    {{- else }}
    cert-manager.io/cluster-issuer: letsencrypt
    {{- end }}
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
      {{- range $defaultedIngress.hosts }}
        - {{ .host }}
      {{- end }}
    {{- else }}
    {{- with $defaultedIngress.tls }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- end }}
  {{- end }}
  rules:
  {{- $ports := list }}
  {{- range $containerName, $container := $deploymentConfig.containers }}
    {{- range $portName, $port := $container.ports }}
      {{- $ports = append $ports (dict "name" $portName "port" $port.containerPort) }}
    {{- end }}
  {{- end }}
  {{- $firstPort := first $ports }}
  {{- range $defaultedIngress.hosts }}
    - host: {{ .host }}
      http:
        paths:
        {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType | default "Prefix" }}
            backend:
              service:
                name: {{ $deploymentName }}
                port:
                  {{- if .port }}
                  number: {{ .port }}
                  {{- else if .portName }}
                  name: {{ .portName }}
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

{{/* Updated ServiceMonitor template */}}
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

apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ $deploymentName }}
  labels:
    {{- include "ks-universal.labels" (dict "Chart" $root.Chart "Release" $root.Release "name" $deploymentName) | nindent 4 }}
    {{- if $deploymentConfig.serviceMonitor }}
    {{- with $deploymentConfig.serviceMonitor.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- end }}
spec:
  selector:
    matchLabels:
      {{- include "ks-universal.componentLabels" (dict "name" $deploymentName "root" $root) | nindent 6 }}
  endpoints:
  - port: {{ $metricsPort }}
    {{- if $deploymentConfig.serviceMonitor }}
    {{- with $deploymentConfig.serviceMonitor.interval }}
    interval: {{ . }}
    {{- end }}
    {{- with $deploymentConfig.serviceMonitor.scrapeTimeout }}
    scrapeTimeout: {{ . }}
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
  {{- if and $deploymentConfig.serviceMonitor $deploymentConfig.serviceMonitor.namespaceSelector }}
  namespaceSelector:
    {{- toYaml $deploymentConfig.serviceMonitor.namespaceSelector | nindent 4 }}
  {{- end }}
{{- end }}

{{/* Helper для автоматического создания certificate */}}
{{- define "ks-universal.autoCertificate" -}}
{{- $deploymentName := .deploymentName }}
{{- $deploymentConfig := .deploymentConfig }}
{{- $root := .root }}
{{- $defaultedIngress := include "ks-universal.ingressDefaults" (dict "ingress" ($deploymentConfig.ingress | default dict) "general" $root.Values.ingressesGeneral) | fromYaml }}

{{- $domains := list }}
{{- range $defaultedIngress.hosts }}
{{- $domains = append $domains .host }}
{{- end }}

{{- $certificateConfig := dict }}
{{- if $deploymentConfig.certificate }}
{{- $certificateConfig = $deploymentConfig.certificate }}
{{- end }}
{{- $_ := set $certificateConfig "domains" $domains }}

{{- include "ks-universal.certificate" (dict "certificateName" $deploymentName "certificateConfig" $certificateConfig "root" $root) }}
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