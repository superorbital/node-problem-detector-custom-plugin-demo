#!/usr/bin/env bash

./chaos/label-pods-with-node.bash

kubectl apply -f chaos/network-partition.yaml
