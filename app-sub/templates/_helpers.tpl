{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "mia.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mia.fullname" -}}
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
Create a fully qualified agent name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mia.agent.fullname" -}}
{{- if .Values.agent.fullnameOverride -}}
{{- .Values.agent.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name .Values.agent.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.agent.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified server name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mia.server.fullname" -}}
{{- if .Values.server.fullnameOverride -}}
    {{- .Values.server.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
    {{- $name := default .Chart.Name .Values.nameOverride -}}
    {{- if contains $name .Release.Name -}}
         {{- printf "%s-%s" .Release.Name .Values.server.name | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
        {{- printf "%s-%s-%s" .Release.Name $name .Values.server.name | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
    {{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mia.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create template name
*/}}
{{- define "mia.template.name" -}}
{{-  base .Template.Name | trimSuffix ".yaml"  -}}
{{- end -}}


{{/*
Create template
*/}}
{{- define "mia.template" -}}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ template "mia.template.name" .}}-{{.Values.spec.destination.namespace}}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: {{ .Values.spec.source.repoURL }}
    targetRevision: {{ .Values.spec.source.targetRevision }}
    path: {{ template "mia.template.name" .}}
  destination:
    namespace: {{.Values.spec.destination.namespace}}
    name: {{ .Values.spec.destination.name }}
  syncPolicy:
    automated:
      prune: true

{{- end -}}

{{/*
Create the name of the agent service account to use.
*/}}
{{- define "mia.serviceAccountName.agent" -}}
{{- if .Values.serviceAccounts.agent.create -}}
    {{ default (include "mia.agent.fullname" .) .Values.serviceAccounts.agent.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccounts.agent.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the server service account to use.
*/}}
{{- define "mia.serviceAccountName.server" -}}
{{- if .Values.serviceAccounts.server.create -}}
    {{ default (include "mia.server.fullname" .) .Values.serviceAccounts.server.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccounts.server.name }}
{{- end -}}
{{- end -}}

{{/*
Generate certificates for kiam server and agent
*/}}
{{- define "mia.agent.gen-certs" -}}
{{- $ca := .ca | default (genCA "kiam-ca" 365) -}}
{{- $_ := set . "ca" $ca -}}
{{- $cert := genSignedCert "Kiam Agent" nil nil 365 $ca -}}
{{.Values.agent.tlsCerts.caFileName }}: {{ $ca.Cert | b64enc }}
{{.Values.agent.tlsCerts.certFileName }}: {{ $cert.Cert | b64enc }}
{{.Values.agent.tlsCerts.keyFileName }}: {{ $cert.Key | b64enc }}
{{- end -}}
{{- define "mia.server.gen-certs" -}}
{{- $altNames := list (include "mia.server.fullname" .) (printf "%s:%d" (include "mia.server.fullname" .) .Values.server.service.port) (printf "127.0.0.1:%d" .Values.server.service.targetPort) -}}
{{- $ca := .ca | default (genCA "kiam-ca" 365) -}}
{{- $_ := set . "ca" $ca -}}
{{- $cert := genSignedCert "Kiam Server" (list "127.0.0.1") $altNames 365 $ca -}}
{{.Values.server.tlsCerts.caFileName }}: {{ $ca.Cert | b64enc }}
{{.Values.server.tlsCerts.certFileName }}: {{ $cert.Cert | b64enc }}
{{.Values.server.tlsCerts.keyFileName }}: {{ $cert.Key | b64enc }}
{{- end -}}