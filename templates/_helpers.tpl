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