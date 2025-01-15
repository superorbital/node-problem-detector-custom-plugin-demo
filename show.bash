#!/usr/bin/env bash

kubectl get nodes -o yaml | \
  yq '.items[] | {
    "name": .metadata.name,
    "condition": .status.conditions[] | select(.type == "NetworkProblem")
  }'
