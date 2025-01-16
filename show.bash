#!/usr/bin/env bash

kubectl get nodes -o yaml | \
  condition="${1-NetworkProblem}" yq '.items[] | {
    "name": .metadata.name,
    "condition": .status.conditions[] | select(.type == env(condition))
  }'
