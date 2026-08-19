{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "keycloak-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields (e.g. DNS labels) have that limit.
*/}}
{{- define "keycloak-operator.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "keycloak-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "keycloak-operator.labels" -}}
helm.sh/chart: {{ include "keycloak-operator.chart" . }}
{{ include "keycloak-operator.selectorLabels" . }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: keycloak
{{- end -}}

{{/*
Selector labels (must stay immutable for the lifetime of the Deployment).
*/}}
{{- define "keycloak-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "keycloak-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use.
*/}}
{{- define "keycloak-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "keycloak-operator.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Operator image reference.
*/}}
{{- define "keycloak-operator.image" -}}
{{- if .Values.image.digest -}}
{{- printf "%s/%s@%s" .Values.image.registry .Values.image.repository .Values.image.digest -}}
{{- else -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository $tag -}}
{{- end -}}
{{- end -}}

{{/*
Keycloak image reference deployed by the operator for `Keycloak` CR instances
(RELATED_IMAGE_KEYCLOAK).
*/}}
{{- define "keycloak-operator.keycloakImage" -}}
{{- if .Values.keycloakImage.digest -}}
{{- printf "%s/%s@%s" .Values.keycloakImage.registry .Values.keycloakImage.repository .Values.keycloakImage.digest -}}
{{- else -}}
{{- $tag := default .Chart.AppVersion .Values.keycloakImage.tag -}}
{{- printf "%s/%s:%s" .Values.keycloakImage.registry .Values.keycloakImage.repository $tag -}}
{{- end -}}
{{- end -}}

{{/*
Returns "true" when the operator runs cluster-wide (watchNamespaces == "*").
*/}}
{{- define "keycloak-operator.clusterWide" -}}
{{- if and (kindIs "string" .Values.watchNamespaces) (eq .Values.watchNamespaces "*") -}}
{{- true -}}
{{- else -}}
{{- false -}}
{{- end -}}
{{- end -}}

{{/*
Value of the QUARKUS_OPERATOR_SDK_CONTROLLERS_*_NAMESPACES environment variables.
- cluster-wide      -> JOSDK_ALL_NAMESPACES
- current namespace -> JOSDK_WATCH_CURRENT
- list              -> comma-separated namespace list
*/}}
{{- define "keycloak-operator.josdkNamespaces" -}}
{{- if eq (include "keycloak-operator.clusterWide" .) "true" -}}
{{- "JOSDK_ALL_NAMESPACES" -}}
{{- else if empty .Values.watchNamespaces -}}
{{- "JOSDK_WATCH_CURRENT" -}}
{{- else if kindIs "string" .Values.watchNamespaces -}}
{{- "JOSDK_WATCH_CURRENT" -}}
{{- else -}}
{{- join "," .Values.watchNamespaces -}}
{{- end -}}
{{- end -}}

{{/*
Name of the `Keycloak` CR optionally created by this chart.
Used as the default `keycloakCRName` for `realmImports` entries.
*/}}
{{- define "keycloak-operator.keycloakCRName" -}}
{{- default .Release.Name .Values.keycloak.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Name of the Secret holding the bootstrap admin credentials referenced by
`spec.bootstrapAdmin.user.secret`. Prefers an existing Secret when set.
*/}}
{{- define "keycloak-operator.bootstrapAdminSecretName" -}}
{{- $name := .Values.keycloak.bootstrapAdmin.existingSecret | default .Values.keycloak.bootstrapAdmin.secretName | default (printf "%s-bootstrap-admin" (include "keycloak-operator.keycloakCRName" .)) -}}
{{- $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Returns "true" when the chart should inject `spec.bootstrapAdmin` into the
`Keycloak` CR (i.e. the user has not configured `spec.bootstrapAdmin` manually
and either an existing Secret is referenced or the Secret should be created).
*/}}
{{- define "keycloak-operator.bootstrapAdminInjected" -}}
{{- $spec := .Values.keycloak.spec | default dict -}}
{{- if hasKey $spec "bootstrapAdmin" -}}
{{- false -}}
{{- else if or .Values.keycloak.bootstrapAdmin.existingSecret .Values.keycloak.bootstrapAdmin.create -}}
{{- true -}}
{{- else -}}
{{- false -}}
{{- end -}}
{{- end -}}
