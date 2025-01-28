{{- define "labels" -}}
{{- range $key, $value := .Values.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- define "chatbot-ui.imageref" -}}
"{{ .Values.image.repo }}:{{ .Values.image.ref | default (print .Chart.AppVersion) }}"
{{- end }}
