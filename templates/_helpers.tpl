# _helpers.tpl
{{/*
Expand the name of the chart.
*/}}
{{- define "ks-universal.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
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
app.kubernetes.io/name: {{ include "ks-universal.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ks-universal.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ks-universal.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the deployment selector labels
*/}}
{{- define "ks-universal.deploymentSelector" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .instance }}
{{- end }}

{{/*
Validation for required fields
*/}}
{{- define "ks-universal.validateContainer" -}}
{{- $container := .container }}
{{- $name := .name }}
{{- if not $container.image }}
{{- fail (printf "Container %s: image is required" $name) }}
{{- end }}
{{- if not $container.imageTag }}
{{- fail (printf "Container %s: imageTag is required" $name) }}
{{- end }}
{{/* Проверка полей valueFrom в env */}}
{{- if $container.env }}
{{- range $container.env }}
{{- if and (not .value) (not .valueFrom) }}
{{- fail (printf "Container %s: either value or valueFrom must be specified for environment variable %s" $name .name) }}
{{- end }}
{{- end }}
{{- end }}
{{/* Проверка полей envFrom */}}
{{- if $container.envFrom }}
{{- range $container.envFrom }}
{{- if not .type }}
{{- fail (printf "Container %s: envFrom type is required (configMap or secret)" $name) }}
{{- end }}
{{- if not .configName }}
{{- fail (printf "Container %s: envFrom configName is required" $name) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Merge deployment values with general defaults
*/}}
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
  {{- if $general.lifecycle }}
    {{- range $containerName, $container := $result.containers }}
      {{- if not $container.lifecycle }}
        {{- $_ := set $container "lifecycle" $general.lifecycle }}
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

{{/* Создаем имя конфига */}}
{{- define "ks-universal.configName" -}}
{{- printf "%s-%s" .root.Release.Name .name }}
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

{{/* Добавляем новый helper для валидации портов */}}
{{- define "ks-universal.validatePorts" -}}
{{- $ports := .ports }}
{{- $containerName := .containerName }}
{{- $portNames := dict }}
{{- range $portName, $port := $ports }}
  {{- if hasKey $portNames $portName }}
    {{- fail (printf "Container %s: duplicate port name %s" $containerName $portName) }}
  {{- end }}
  {{- $_ := set $portNames $portName true }}
  {{- $portValue := int $port.containerPort }}
  {{- if not (and (gt $portValue 0) (le $portValue 65535)) }}
    {{- fail (printf "Container %s: port %s must be between 1 and 65535" $containerName $portName) }}
  {{- end }}
{{- end }}
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

{{/* Если задан affinity в конфиге - используем его */}}
{{- if $config.affinity }}
    {{- $result = $config.affinity }}
{{/* Иначе если нужно создать soft anti-affinity */}}
{{- else if $createSoftAntiAffinity }}
    {{- $result = include "ks-universal.softAntiAffinity" (dict "deploymentName" $deploymentName) | fromYaml }}
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

{{/* Helper для генерации контейнеров */}}
{{- define "ks-universal.containers" -}}
{{- $root := .root }}
{{- $containers := .containers }}
{{- range $containerName, $container := $containers }}
{{- include "ks-universal.validateContainer" (dict "container" $container "name" $containerName) }}
- name: {{ $containerName }}
  image: {{ include "ks-universal.tplValue" (dict "value" $container.image "context" $root) }}:{{ include "ks-universal.tplValue" (dict "value" $container.imageTag "context" $root) }}
  {{- if $container.args }}
  args:
    {{- toYaml $container.args | nindent 12 }}
  {{- end }}
  {{- if $container.ports }}
  {{- include "ks-universal.validatePorts" (dict "ports" $container.ports "containerName" $containerName) }}
  ports:
    {{- range $portName, $port := $container.ports }}
    - name: {{ $portName }}
      containerPort: {{ $port.containerPort }}
      protocol: {{ $port.protocol | default "TCP" }}
    {{- end }}
  {{- end }}
  {{- if or $container.env $container.envFrom }}
  {{- if $container.envFrom }}
  envFrom:
    {{- range $container.envFrom }}
    - {{ .type }}Ref:
        name: {{ include "ks-universal.configName" (dict "root" $root "name" .configName) }}
    {{- end }}
  {{- end }}
  {{- if $container.env }}
  env:
    {{- range $container.env }}
    - name: {{ .name }}
      {{- if .value }}
      value: {{ .value | quote }}
      {{- else if .valueFrom }}
      valueFrom:
        {{- if .valueFrom.configMapKeyRef }}
        configMapKeyRef:
          name: {{ include "ks-universal.configName" (dict "root" $root "name" .valueFrom.configMapKeyRef.name) }}
          key: {{ .valueFrom.configMapKeyRef.key }}
        {{- else if .valueFrom.secretKeyRef }}
        secretKeyRef:
          name: {{ include "ks-universal.configName" (dict "root" $root "name" .valueFrom.secretKeyRef.name) }}
          key: {{ .valueFrom.secretKeyRef.key }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- with $container.resources }}
  resources:
    {{- toYaml . | nindent 12 }}
  {{- end }}
  {{- if $container.probes }}
  {{- if $container.probes.livenessProbe }}
  livenessProbe:
    {{- toYaml $container.probes.livenessProbe | nindent 12 }}
  {{- end }}
  {{- if $container.probes.readinessProbe }}
  readinessProbe:
    {{- toYaml $container.probes.readinessProbe | nindent 12 }}
  {{- end }}
  {{- if $container.probes.startupProbe }}
  startupProbe:
    {{- toYaml $container.probes.startupProbe | nindent 12 }}
  {{- end }}
  {{- end }}
  {{- with $container.lifecycle }}
  lifecycle:
    {{- if .postStart }}
    postStart:
      {{- toYaml .postStart | nindent 14 }}
    {{- end }}
    {{- if .preStop }}
    preStop:
      {{- toYaml .preStop | nindent 14 }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}