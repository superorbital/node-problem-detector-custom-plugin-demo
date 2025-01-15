#!/usr/bin/env bash

# Get all pods in all namespaces
pods=$(kubectl get pods --all-namespaces --template='{{range .items}}{{.metadata.namespace}}/{{.metadata.name}}/{{.spec.nodeName}}{{"\n"}}{{end}}')

# Loop through each pod
while IFS=/ read -r namespace pod node_name; do
  # Label the pod with the nodeName
  kubectl label pods "$pod" -n "$namespace" nodeName="$node_name" --overwrite
done <<< "$pods"
