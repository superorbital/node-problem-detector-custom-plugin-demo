FROM registry.k8s.io/node-problem-detector/node-problem-detector:v0.8.19

# Just a source of a kubectl binary.
COPY --from=rancher/kubectl:v1.31.4 /bin/kubectl /usr/local/bin/kubectl
