{{/*
Expand the name of the chart.
*/}}
{{- define "prospectml.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "prospectml.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "prospectml.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "prospectml.labels" -}}
helm.sh/chart: {{ include "prospectml.chart" . }}
{{ include "prospectml.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "prospectml.selectorLabels" -}}
app.kubernetes.io/name: {{ include "prospectml.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "prospectml.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "prospectml.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the database URL
*/}}
{{- define "prospectml.databaseUrl" -}}
{{- if .Values.postgresql.enabled }}
{{- $host := printf "%s-postgresql" (include "prospectml.fullname" .) }}
{{- $port := .Values.postgresql.primary.service.port | default 5432 }}
{{- $user := .Values.postgresql.auth.username }}
{{- $pass := .Values.postgresql.auth.password }}
{{- $db := .Values.postgresql.auth.database }}
postgresql://{{ $user }}:{{ $pass }}@{{ $host }}:{{ $port }}/{{ $db }}
{{- else if .Values.database.external.enabled }}
{{- $host := .Values.database.external.host }}
{{- $port := .Values.database.external.port }}
{{- $user := .Values.database.external.username }}
{{- $pass := .Values.database.external.password }}
{{- $db := .Values.database.external.database }}
{{- $sslmode := .Values.database.external.sslmode }}
postgresql://{{ $user }}:{{ $pass }}@{{ $host }}:{{ $port }}/{{ $db }}?sslmode={{ $sslmode }}
{{- end }}
{{- end }}