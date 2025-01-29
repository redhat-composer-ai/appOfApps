{{- define "labels" -}}
{{- range $key, $value := .Values.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- define "chatbot-ui.imageref" -}}
"{{ .Values.image.repository }}:{{ .Values.image.tag | default (print .Chart.AppVersion) }}"
{{- end }}
