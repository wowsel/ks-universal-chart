{{/*
Common validation helpers
*/}}

{{/* Nil check helper */}}
{{- define "ks-universal.validateNotNil" -}}
{{- $value := .value -}}
{{- $field := .field -}}
{{- $context := .context -}}
{{- if eq ($value | toString) "<nil>" -}}
{{- fail (printf "%s: %s must not be nil" $context $field) -}}
{{- end -}}
{{- end -}}

{{/* Required field helper */}}
{{- define "ks-universal.validateRequired" -}}
{{- $object := .object -}}
{{- $field := .field -}}
{{- $context := .context -}}
{{- if not (hasKey $object $field) -}}
{{- fail (printf "%s: field '%s' is required" $context $field) -}}
{{- end -}}
{{- end -}}

{{/* Range validation helper */}}
{{- define "ks-universal.validateRange" -}}
{{- $value := .value -}}
{{- $min := .min -}}
{{- $max := .max -}}
{{- $field := .field -}}
{{- $context := .context -}}
{{- if and $value (or (lt $value $min) (gt $value $max)) -}}
{{- fail (printf "%s: %s must be between %d and %d" $context $field $min $max) -}}
{{- end -}}
{{- end -}}

{{/*
Context validation
*/}}
{{- define "ks-universal.validateContext" -}}
{{- $root := . -}}
{{- if not $root.Chart -}}
{{- fail "Root context must contain Chart information" -}}
{{- end -}}
{{- if not $root.Release -}}
{{- fail "Root context must contain Release information" -}}
{{- end -}}
{{- if not $root.Release.Name -}}
{{- fail "Release.Name must not be empty" -}}
{{- end -}}
{{- if not $root.Release.Service -}}
{{- fail "Release.Service must not be empty" -}}
{{- end -}}
{{- end -}}

{{/*
Ports validation
*/}}
{{- define "ks-universal.validatePorts" -}}
{{- $ports := .ports }}
{{- $containerName := .containerName }}
{{- $context := .context }}
{{- $portNames := dict }}
{{- range $portName, $port := $ports }}
  {{- if hasKey $portNames $portName }}
    {{- fail (printf "%s - Container %s: duplicate port name %s" $context $containerName $portName) }}
  {{- end }}
  {{- $_ := set $portNames $portName true }}
  {{- $portValue := int $port.containerPort }}
  {{- if not (and (gt $portValue 0) (le $portValue 65535)) }}
    {{- fail (printf "%s - Container %s: port %s must be between 1 and 65535" $context $containerName $portName) }}
  {{- end }}
{{- end }}
{{- end }}

{{/* SecretRefs validation */}}
{{- define "ks-universal.validateSecretRefs" -}}
{{- $secretRefs := .secretRefs -}}
{{- $context := .context -}}

{{- if not $secretRefs -}}
{{- fail (printf "%s: secretRefs configuration must not be empty" $context) -}}
{{- end -}}

{{- range $refName, $refConfig := $secretRefs -}}
{{- if not (kindIs "slice" $refConfig) -}}
{{- fail (printf "%s: secretRef %s must be a list of environment variables" $context $refName) -}}
{{- end -}}

{{- range $refConfig -}}
{{- if not .name -}}
{{- fail (printf "%s: name is required for secretRef %s" $context $refName) -}}
{{- end -}}
{{- if not .secretKeyRef -}}
{{- fail (printf "%s: secretKeyRef is required for secretRef %s env %s" $context $refName .name) -}}
{{- end -}}
{{- if not .secretKeyRef.name -}}
{{- fail (printf "%s: secretKeyRef.name is required for secretRef %s env %s" $context $refName .name) -}}
{{- end -}}
{{- if not .secretKeyRef.key -}}
{{- fail (printf "%s: secretKeyRef.key is required for secretRef %s env %s" $context $refName .name) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Container validation */}}
{{- define "ks-universal.validateContainer" -}}
{{- $containerName := .containerName -}}
{{- $container := .container -}}
{{- $context := .context -}}
{{- $root := .root -}}

{{- if not $container.image -}}
{{- fail (printf "%s - Container %s: image is required" $context $containerName) -}}
{{- end -}}

{{- if not $container.imageTag -}}
{{- fail (printf "%s - Container %s: imageTag is required" $context $containerName) -}}
{{- end -}}

{{/* Validate secretRefs if defined */}}
{{- if and $container.secretRefs $root.Values.secretRefs -}}
{{- range $container.secretRefs -}}
{{- if not (hasKey $root.Values.secretRefs .) -}}
{{- fail (printf "%s - Container %s: referenced secretRef '%s' not found in .Values.secretRefs" $context $containerName .) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Validate env valueFrom */}}
{{- if $container.env -}}
{{- range $container.env -}}
{{- if and (not .value) (not .valueFrom) -}}
{{- fail (printf "%s - Container %s: either value or valueFrom must be specified for environment variable %s" $context $containerName .name) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Validate envFrom */}}
{{- if $container.envFrom -}}
{{- range $container.envFrom -}}
{{- if not .type -}}
{{- fail (printf "%s - Container %s: envFrom type is required (configMap or secret)" $context $containerName) -}}
{{- end -}}
{{- if not .configName -}}
{{- fail (printf "%s - Container %s: envFrom configName is required" $context $containerName) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Validate ports */}}
{{- if $container.ports -}}
{{- include "ks-universal.validatePorts" (dict "ports" $container.ports "containerName" $containerName "context" $context) }}
{{- end -}}
{{- end -}}

{{/*
HPA validation
*/}}
{{- define "ks-universal.validateHPA" -}}
{{- $name := .name -}}
{{- $config := .config -}}

{{- if not $config -}}
{{- fail (printf "HPA %s: configuration must not be empty" $name) -}}
{{- end -}}

{{- if not $config.maxReplicas -}}
{{- fail (printf "HPA %s: maxReplicas is required" $name) -}}
{{- end -}}

{{- if not $config.metrics -}}
{{- fail (printf "HPA %s: metrics configuration is required" $name) -}}
{{- end -}}

{{- range $index, $metric := $config.metrics -}}
{{- if not $metric.type -}}
{{- fail (printf "HPA %s: metric type is required" $name) -}}
{{- end -}}
{{- if not (or (eq $metric.type "Resource") (eq $metric.type "Pods") (eq $metric.type "Object") (eq $metric.type "External") (eq $metric.type "ContainerResource")) -}}
{{- fail (printf "HPA %s: invalid metric type '%s'. Must be one of: Resource, Pods, Object, External, ContainerResource" $name $metric.type) -}}
{{- end -}}
{{- if eq $metric.type "Resource" -}}
{{- if not $metric.resource -}}
{{- fail (printf "HPA %s: resource configuration is required for Resource metric type" $name) -}}
{{- end -}}
{{- if not $metric.resource.name -}}
{{- fail (printf "HPA %s: resource name is required for Resource metric type" $name) -}}
{{- end -}}
{{- if not (or $metric.resource.target.type $metric.resource.target.averageUtilization $metric.resource.target.averageValue) -}}
{{- fail (printf "HPA %s: resource target configuration is required for Resource metric type" $name) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
PDB validation
*/}}
{{- define "ks-universal.validatePDB" -}}
{{- $name := .name -}}
{{- $config := .config -}}

{{- if not $config -}}
{{- fail (printf "PDB %s: configuration must not be empty" $name) -}}
{{- end -}}

{{- if and $config.minAvailable $config.maxUnavailable -}}
{{- fail (printf "PDB %s: cannot specify both minAvailable and maxUnavailable" $name) -}}
{{- end -}}

{{- if not (or $config.minAvailable $config.maxUnavailable) -}}
{{- fail (printf "PDB %s: either minAvailable or maxUnavailable must be specified" $name) -}}
{{- end -}}

{{- if $config.minAvailable -}}
{{- if not (or (kindIs "string" $config.minAvailable) (kindIs "int" $config.minAvailable)) -}}
{{- fail (printf "PDB %s: minAvailable must be either a number or percentage string" $name) -}}
{{- end -}}
{{- end -}}
{{- if $config.maxUnavailable -}}
{{- if not (or (kindIs "string" $config.maxUnavailable) (kindIs "int" $config.maxUnavailable)) -}}
{{- fail (printf "PDB %s: maxUnavailable must be either a number or percentage string" $name) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
ServiceMonitor validation
*/}}
{{- define "ks-universal.validateServiceMonitor" -}}
{{- $name := .name -}}
{{- $config := .config -}}

{{- if not $config -}}
{{- fail (printf "ServiceMonitor %s: configuration must not be empty" $name) -}}
{{- end -}}

{{/* Validate endpoints configuration */}}
{{- if $config.endpoints -}}
{{- range $endpoint := $config.endpoints -}}
{{- if not $endpoint.port -}}
{{- if not (kindIs "string" $endpoint.port) -}}
{{- fail (printf "ServiceMonitor %s: port must be a string" $name) -}}
{{- end -}}
{{- end -}}

{{- if $endpoint.interval -}}
{{- if not (regexMatch "^([0-9]+(ms|s|m|h))+$" $endpoint.interval) -}}
{{- fail (printf "ServiceMonitor %s: invalid interval format. Must be a valid duration (e.g., 30s, 1m, 1h)" $name) -}}
{{- end -}}
{{- end -}}

{{- if $endpoint.scrapeTimeout -}}
{{- if not (regexMatch "^([0-9]+(ms|s|m|h))+$" $endpoint.scrapeTimeout) -}}
{{- fail (printf "ServiceMonitor %s: invalid scrapeTimeout format. Must be a valid duration (e.g., 30s, 1m, 1h)" $name) -}}
{{- end -}}
{{- end -}}

{{- if $endpoint.path -}}
{{- if not (kindIs "string" $endpoint.path) -}}
{{- fail (printf "ServiceMonitor %s: path must be a string" $name) -}}
{{- end -}}
{{- end -}}

{{- if $endpoint.scheme -}}
{{- if not (or (eq $endpoint.scheme "http") (eq $endpoint.scheme "https")) -}}
{{- fail (printf "ServiceMonitor %s: scheme must be either 'http' or 'https'" $name) -}}
{{- end -}}
{{- end -}}

{{- if $endpoint.tlsConfig -}}
{{- if not (kindIs "map" $endpoint.tlsConfig) -}}
{{- fail (printf "ServiceMonitor %s: tlsConfig must be a map" $name) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Validate namespaceSelector if present */}}
{{- if $config.namespaceSelector -}}
{{- if not (kindIs "map" $config.namespaceSelector) -}}
{{- fail (printf "ServiceMonitor %s: namespaceSelector must be a map" $name) -}}
{{- end -}}
{{- end -}}

{{/* Validate labels if present */}}
{{- if $config.labels -}}
{{- if not (kindIs "map" $config.labels) -}}
{{- fail (printf "ServiceMonitor %s: labels must be a map" $name) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
ServiceAccount validation
*/}}
{{- define "ks-universal.validateServiceAccount" -}}
{{- $name := .name -}}
{{- $config := .config -}}

{{- if not $config -}}
{{- fail (printf "ServiceAccount %s: configuration must not be empty" $name) -}}
{{- end -}}

{{- if $config.annotations -}}
{{- if not (kindIs "map" $config.annotations) -}}
{{- fail (printf "ServiceAccount %s: annotations must be a map" $name) -}}
{{- end -}}
{{- end -}}

{{- if $config.imagePullSecrets -}}
{{- if not (kindIs "slice" $config.imagePullSecrets) -}}
{{- fail (printf "ServiceAccount %s: imagePullSecrets must be a list" $name) -}}
{{- end -}}
{{- range $secret := $config.imagePullSecrets -}}
{{- if not $secret.name -}}
{{- fail (printf "ServiceAccount %s: name is required for each imagePullSecret" $name) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Certificate validation
*/}}
{{- define "ks-universal.validateCertificate" -}}
{{- $deploymentConfig := . -}}
{{- if and $deploymentConfig.autoCreateCertificate (not $deploymentConfig.autoCreateIngress) -}}
{{- fail (printf "autoCreateCertificate requires autoCreateIngress to be enabled") -}}
{{- end -}}
{{- if and $deploymentConfig.autoCreateCertificate (not $deploymentConfig.ingress) -}}
{{- fail (printf "autoCreateCertificate requires ingress configuration") -}}
{{- end -}}
{{- end -}}

{{/*
Computed Ingress Host
*/}}
{{- define "ks-universal.computedIngressHost" -}}
  {{- $host := .host | default "" | trim -}}
  {{- $subdomain := .subdomain | default "" | trim -}}
  {{- $globalDomain := .globalDomain | default "" | trim -}}
  {{- $domainRegex := "^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)(?:\\.(?:[a-zA-Z]{2,}))+$" -}}
  {{- $subdomainRegex := "^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$" -}}

  {{- if $host }}
    {{- if regexMatch $domainRegex $host }}
      {{ $host }}
    {{- else }}
      {{ fail (printf "Invalid host value: '%s'. Он должен соответствовать шаблону домена." $host) }}
    {{- end }}
  {{- else if $subdomain }}
    {{- if not $globalDomain }}
      {{ fail "Global domain должен быть указан, когда используется subdomain." }}
    {{- end }}
    {{- if regexMatch $subdomainRegex $subdomain }}
      {{ printf "%s.%s" $subdomain $globalDomain }}
    {{- else }}
      {{ fail (printf "Invalid subdomain value: '%s'. Допустимы только строчные буквы, цифры и дефисы." $subdomain) }}
    {{- end }}
  {{- else if $globalDomain }}
    {{- if regexMatch $domainRegex $globalDomain }}
      {{ $globalDomain }}
    {{- else }}
      {{ fail (printf "Invalid global domain value: '%s'" $globalDomain) }}
    {{- end }}
  {{- else }}
    {{ fail "Не указаны ни host, ни subdomain, ни global domain." }}
  {{- end }}
{{- end }}



{{/*
Ingress validation
*/}}
{{- define "ks-universal.validateIngress" -}}
  {{- $root := .root -}}
  {{- $name := .name -}}
  {{- $config := .config -}}
  {{- $generic := $root.Values.generic | default dict -}}
  {{- $ingressesGeneral := $generic.ingressesGeneral | default dict -}}
  {{- $globalDomain := $ingressesGeneral.domain | default "" | trim }}
  
  {{- if not $config -}}
    {{ fail (printf "Ingress %s: configuration must not be empty" $name) }}
  {{- end }}

  {{- if not $config.hosts -}}
    {{ fail (printf "Ingress %s: hosts configuration is required" $name) }}
  {{- end }}

  {{- range $hostEntry := $config.hosts }}
    {{- /* Вычисляем итоговый хост с помощью нашей функции */ -}}
    {{- $computedHost := include "ks-universal.computedIngressHost" (dict "host" $hostEntry.host "subdomain" $hostEntry.subdomain "globalDomain" $globalDomain) | trim }}
    {{- if not $computedHost }}
      {{ fail (printf "Ingress %s: computed host is empty for entry %+v" $name $hostEntry) }}
    {{- end }}
    {{/* Здесь можно добавить дополнительные проверки, если необходимо */}}
  {{- end }}
{{- end }}



{{/*
Config validation
*/}}
{{- define "ks-universal.validateConfig" -}}
{{- $configName := .configName -}}
{{- $config := .config -}}

{{- if not $config -}}
{{- fail (printf "Config %s: configuration must not be empty" $configName) -}}
{{- end -}}

{{- if not $config.type -}}
{{- fail (printf "Config %s: type is required" $configName) -}}
{{- end -}}

{{- if not (or (eq $config.type "secret") (eq $config.type "configMap")) -}}
{{- fail (printf "Config %s: type must be either 'secret' or 'configMap'" $configName) -}}
{{- end -}}

{{- if not $config.data -}}
{{- fail (printf "Config %s: data is required" $configName) -}}
{{- end -}}
{{- end -}}

{{/*
Service validation
*/}}
{{- define "ks-universal.validateService" -}}
{{- $serviceName := .serviceName -}}
{{- $serviceConfig := .serviceConfig -}}

{{- if not $serviceConfig -}}
{{- fail (printf "Service %s: configuration must not be empty" $serviceName) -}}
{{- end -}}

{{- if not $serviceConfig.ports -}}
{{- fail (printf "Service %s: ports configuration is required" $serviceName) -}}
{{- end -}}

{{- range $serviceConfig.ports -}}
{{- if not .port -}}
{{- fail (printf "Service %s: port is required for each port configuration" $serviceName) -}}
{{- end -}}
{{- if not .targetPort -}}
{{- fail (printf "Service %s: targetPort is required for each port configuration" $serviceName) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
PVC validation
*/}}
{{- define "ks-universal.validatePVC" -}}
{{- $pvcName := .pvcName -}}
{{- $pvcConfig := .pvcConfig -}}

{{- if not $pvcConfig -}}
{{- fail (printf "PVC %s: configuration must not be empty" $pvcName) -}}
{{- end -}}

{{- if not $pvcConfig.accessModes -}}
{{- fail (printf "PVC %s: accessModes is required" $pvcName) -}}
{{- end -}}

{{- if not $pvcConfig.size -}}
{{- fail (printf "PVC %s: size is required" $pvcName) -}}
{{- end -}}
{{- end -}}

{{/*
Deployment validation
*/}}
{{- define "ks-universal.validateDeployment" -}}
{{- $deploymentName := .deploymentName -}}
{{- $deploymentConfig := .deploymentConfig -}}
{{- $root := .root -}}

{{- if not $deploymentConfig -}}
{{- fail (printf "Deployment %s: configuration must not be empty" $deploymentName) -}}
{{- end -}}

{{/* Container validation */}}
{{- if not $deploymentConfig.containers -}}
{{- fail (printf "Deployment %s: containers configuration is required" $deploymentName) -}}
{{- end -}}
{{- range $containerName, $container := $deploymentConfig.containers -}}
{{- include "ks-universal.validateContainer" (dict "containerName" $containerName "container" $container "context" (printf "Deployment %s" $deploymentName) "root" $root) -}}
{{- end -}}

{{/* HPA validation */}}
{{- if $deploymentConfig.hpa -}}
{{- include "ks-universal.validateHPA" (dict "name" $deploymentName "config" $deploymentConfig.hpa) -}}
{{- end -}}

{{/* PDB validation */}}
{{- if $deploymentConfig.pdb -}}
{{- include "ks-universal.validatePDB" (dict "name" $deploymentName "config" $deploymentConfig.pdb) -}}
{{- end -}}

{{/* ServiceMonitor validation */}}
{{- if $deploymentConfig.serviceMonitor -}}
{{- include "ks-universal.validateServiceMonitor" (dict "name" $deploymentName "config" $deploymentConfig.serviceMonitor) -}}
{{- end -}}

{{/* ServiceAccount validation */}}
{{- if $deploymentConfig.serviceAccount -}}
{{- include "ks-universal.validateServiceAccount" (dict "name" $deploymentName "config" $deploymentConfig.serviceAccount) -}}
{{- end -}}

{{/* Certificate and Ingress validation */}}
{{- if $deploymentConfig.autoCreateCertificate -}}
{{- include "ks-universal.validateCertificate" $deploymentConfig -}}
{{- end -}}
{{- end -}}

{{/*
CronJob validation
*/}}
{{- define "ks-universal.validateCronJob" -}}
{{- $cronJobName := .cronJobName -}}
{{- $cronJobConfig := .cronJobConfig -}}
{{- $root := .root -}}

{{- if not $cronJobConfig -}}
{{- fail (printf "CronJob %s: configuration must not be empty" $cronJobName) -}}
{{- end -}}

{{/* Schedule validation */}}
{{- if not $cronJobConfig.schedule -}}
{{- fail (printf "CronJob %s: schedule is required" $cronJobName) -}}
{{- end -}}

{{/* Container validation */}}
{{- if not $cronJobConfig.containers -}}
{{- fail (printf "CronJob %s: containers configuration is required" $cronJobName) -}}
{{- end -}}
{{- range $containerName, $container := $cronJobConfig.containers -}}
{{- include "ks-universal.validateContainer" (dict "containerName" $containerName "container" $container "context" (printf "CronJob %s" $cronJobName) "root" $root) -}}
{{- end -}}
{{- end -}}

{{/*
Job validation
*/}}
{{- define "ks-universal.validateJob" -}}
{{- $jobName := .jobName -}}
{{- $jobConfig := .jobConfig -}}
{{- $root := .root -}}

{{- if not $jobConfig -}}
{{- fail (printf "Job %s: configuration must not be empty" $jobName) -}}
{{- end -}}

{{/* Container validation */}}
{{- if not $jobConfig.containers -}}
{{- fail (printf "Job %s: containers configuration is required" $jobName) -}}
{{- end -}}
{{- range $containerName, $container := $jobConfig.containers -}}
{{- include "ks-universal.validateContainer" (dict "containerName" $containerName "container" $container "context" (printf "Job %s" $jobName) "root" $root) -}}
{{- end -}}
{{- end -}}

{{/*
Main validation entrypoint
*/}}
{{- define "ks-universal.validate" -}}
{{- $root := . -}}

{{/* Validate global secretRefs if defined */}}
{{- if .Values.secretRefs -}}
{{- include "ks-universal.validateSecretRefs" (dict "secretRefs" .Values.secretRefs "context" "Global") -}}
{{- end -}}

{{/* Context validation */}}
{{- include "ks-universal.validateContext" $root -}}

{{/* Deployments validation */}}
{{- if $root.Values.deployments -}}
{{- range $deploymentName, $deploymentConfig := $root.Values.deployments -}}
{{- include "ks-universal.validateDeployment" (dict "deploymentName" $deploymentName "deploymentConfig" $deploymentConfig "root" $root) -}}
{{- end -}}
{{- end -}}

{{/* CronJobs validation */}}
{{- if $root.Values.cronJobs -}}
{{- range $cronJobName, $cronJobConfig := $root.Values.cronJobs -}}
{{- include "ks-universal.validateCronJob" (dict "cronJobName" $cronJobName "cronJobConfig" $cronJobConfig "root" $root) -}}
{{- end -}}
{{- end -}}

{{/* Jobs validation */}}
{{- if $root.Values.jobs -}}
{{- range $jobName, $jobConfig := $root.Values.jobs -}}
{{- include "ks-universal.validateJob" (dict "jobName" $jobName "jobConfig" $jobConfig "root" $root) -}}
{{- end -}}
{{- end -}}

{{/* Configs validation */}}
{{- if $root.Values.configs -}}
{{- range $configName, $config := $root.Values.configs -}}
{{- include "ks-universal.validateConfig" (dict "configName" $configName "config" $config) -}}
{{- end -}}
{{- end -}}

{{/* Services validation */}}
{{- if $root.Values.services -}}
{{- range $serviceName, $serviceConfig := $root.Values.services -}}
{{- include "ks-universal.validateService" (dict "serviceName" $serviceName "serviceConfig" $serviceConfig) -}}
{{- end -}}
{{- end -}}

{{/* PVCs validation */}}
{{- if $root.Values.persistentVolumeClaims -}}
{{- range $pvcName, $pvcConfig := $root.Values.persistentVolumeClaims -}}
{{- include "ks-universal.validatePVC" (dict "pvcName" $pvcName "pvcConfig" $pvcConfig) -}}
{{- end -}}
{{- end -}}

{{/* Standalone Ingresses validation */}}
{{- if $root.Values.ingresses -}}
{{- range $ingressName, $ingressConfig := $root.Values.ingresses -}}
{{- include "ks-universal.validateIngress" (dict "name" $ingressName "config" $ingressConfig "root" $) }}
{{- end -}}
{{- end -}}
{{- end -}}