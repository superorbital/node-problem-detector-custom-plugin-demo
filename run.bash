#!/usr/bin/env bash

IMAGE_TAG="custom-node-problem-detector"
KIND_CLUSTER_NAME="npd-test"

# Create kind cluster and install chaos-mesh.
# Let the chaos-mesh installer create the cluster with the needed configuration
if ! kind get clusters | grep -q "^${KIND_CLUSTER_NAME}$" >/dev/null ; then
  curl -sSL https://mirrors.chaos-mesh.org/v2.7.0/install.sh | \
    bash -s -- \
    --local kind \
    --kind-version v0.26.0 \
    --k8s-version v1.32.0 \
    --node-num 3 \
    --name $KIND_CLUSTER_NAME
fi

docker build image/ -t ${IMAGE_TAG}

kind load docker-image --name ${KIND_CLUSTER_NAME} ${IMAGE_TAG}

kustomize build --enable-helm npd/ | kubectl apply -f -
