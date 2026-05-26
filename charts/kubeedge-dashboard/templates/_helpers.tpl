{{/*
Expand the name of the chart.
*/}}
{{- define "kubeedge-dashboard.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "kubeedge-dashboard.fullname" -}}
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
Create chart label.
*/}}
{{- define "kubeedge-dashboard.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "kubeedge-dashboard.labels" -}}
helm.sh/chart: {{ include "kubeedge-dashboard.chart" . }}
{{ include "kubeedge-dashboard.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "kubeedge-dashboard.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubeedge-dashboard.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: kubeedge-dashboard
{{- end }}

{{/*
Namespace to deploy into.
*/}}
{{- define "kubeedge-dashboard.namespace" -}}
{{- .Values.namespace.name | default "kubeedge-dashboard" }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "kubeedge-dashboard.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- .Values.serviceAccount.name | default "kubeedge-dashboard" }}
{{- else }}
{{- "default" }}
{{- end }}
{{- end }}
