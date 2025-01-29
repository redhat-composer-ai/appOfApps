{{- define "chatbot-ui.openIdSidecar" }}
        - name: "{{ .Values.name }}-oauth"
          image: "{{ .Values.openid.image.repository }}:{{ .Values.openid.image.tag }}"
          imagePullPolicy: {{ .Values.imagePullPolicy | default "Always" }}
          args:
            - --config=/etc/oauth2_proxy/oauth2_proxy.cfg
            - --http-address=0.0.0.0:4180
            - --https-address=0.0.0.0:4443
          {{- if .Values.openid.metrics.enabled }}
            - --metrics-address=0.0.0.0:44180
          {{- end }}
          ports:
            - containerPort: 4180 #exposed host from existing chart
              protocol: TCP
            {{- if .Values.openid.metrics.enabled }}
            - containerPort: 44180 #exposed host from existing chart
              protocol: TCP
              name: metrics
            {{- end }}
          {{- if .Values.openid.livenessProbe.enabled }}
          livenessProbe:
            httpGet:
              path: /ping
              port: 4180
              scheme: HTTP
            timeoutSeconds: {{ .Values.openid.livenessProbe.timeoutSeconds }}
            initialDelaySeconds: {{ .Values.openid.livenessProbe.initialDelaySeconds }}
          {{- end }}
          {{- if .Values.openid.readinessProbe.enabled }}
          readinessProbe:
            httpGet:
              path: /ready
              port: 4180
              scheme: HTTP
            timeoutSeconds: {{ .Values.openid.readinessProbe.timeoutSeconds }}
            initialDelaySeconds: {{ .Values.openid.readinessProbe.initialDelaySeconds }}
            successThreshold: {{ .Values.openid.readinessProbe.successThreshold }}
            periodSeconds: {{ .Values.openid.readinessProbe.periodSeconds }}
          {{- end }}
          volumeMounts:
            - name: "{{ .Values.name }}-oauth"
              mountPath: /etc/oauth2_proxy/oauth2_proxy.cfg
              subPath: oauth2_proxy.cfg
          #  - mountPath: /etc/pki/tls/certs/generated
          #     name: cert-mount
          #     readOnly: true
{{- end }}
{{- define "chatbot-ui.openIdVolume" }}
        - name: "{{ .Values.name }}-oauth"
          configMap:
            name: "{{ .Values.name }}-oauth"
        # - name: cert-mount
        #   secret:
        #     secretName: "{{ .Values.name }}-certs"
{{- end }}
