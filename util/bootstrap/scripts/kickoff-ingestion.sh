#!/bin/bash

oc project composer-ai-apps

# Check if the statefulset exists
while ! oc get statefulset elasticsearch-es-default >/dev/null 2>&1; do
  echo "Waiting for statefulset 'elasticsearch-es-default' to exist..."
  sleep 5
done

echo "Statefulset 'elasticsearch-es-default' exists."

# Check if the statefulset is running
while [[ $(oc get statefulset elasticsearch-es-default -o jsonpath='{.status.availableReplicas}') != "3" ]]; do
  echo "Waiting for statefulset 'elasticsearch-es-default' to be running..."
  sleep 5
done

# This should work but not sure if we want to give the service account view access to nodes
# And not required for dedicated demo environment
# while [ -z "$gpu_count" ]; do
#   echo "Waiting for GPU nodes to be available..."
#   gpu_count=$(oc get nodes -o jsonpath='{.items[*].status.allocatable.nvidia\.com/gpu}' | grep -o '[0-9]\+' | paste -sd+ - | bc)
# done

while ! oc get pipeline ingestion-pipeline >/dev/null 2>&1; do
  echo "Waiting for pipeline 'ingestion-pipeline' to exist..."
  sleep 5
done

echo "Pipeline 'ingestion-pipeline-${pipeline_suffix}' exists."

# Generate a random alphanumeric string
pipeline_suffix=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)


# Kickoff Tekton pipeline
oc create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: ingestion-pipeline-${pipeline_suffix}
spec:
  pipelineRef:
    name: ingestion-pipeline
  workspaces:
    - name: source
      volumeClaimTemplate:
        metadata:
          creationTimestamp: null
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
          storageClassName: gp3-csi
          volumeMode: Filesystem
EOF
