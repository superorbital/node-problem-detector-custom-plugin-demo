# Demo of custom plugin for node-problem-detector

This repository is a demonstration of a custom plugin for node-problem-detector.

It was intended to have a plugin that demonstrates detecting a network problem
with the node. Instead, it shows that network-problem-detector is not
appropriate for detecting such problems because it detects problems from the
node and therefore cannot update the api-server.

It should still be useful for gaining an understanding of how to make custom
NPD plugins in general.

## Contents

### `npd/`

Contains a deployment of node-problem-detector configured with a custom plugin.

I've used kustomize to render and deploy the helm chart, but Helm can of course
be used instead.

The interesting bits are in `npd/values.yaml`. This configures the daemonset to
use a custom image, and adds a configmap with the plugin definition and script.

See also the comments at the end of `values.yaml` explaining the plugin
configuration.

### `image/`

A custom image that extends the node-problem-detector image to add `kubectl`
which is used by the plugin script.

### `chaos/`

Scripts and configuration for chaos-mesh to cause a network partition.

Chaos-mesh applies experiments more at the Pod level. Therefore, to simulate a
node partition, this applies the experiment to the pods that are running on a
node. To do this it must label the pods with their node name and then use a
label selector.

Only pods in the `kube-system` namespace are selected for this demo since that
is where the NPD daemonset is deployed. Other namespaces could be added, but
the `chaos-mesh` namespace should never be included.

## Prerequisites

- `docker`
  - If using colima on MacOS, start it with `colima start --network-address`
- `kind`
- `kustomize`
- `curl`
- [`yq`](https://github.com/mikefarah/yq)

## Running

Simply execute `./run.bash` to start a cluster using `kind` and with
`chaos-mesh` installed. The `chaos-mesh` installer will configure and create
the kind cluster with the settings it needs to run correctly.

After starting, the custom plugin should provide node conditions with
`type: NetworkProblem`, which can be gathered with `./show.bash`.

Next, let's introduce a problem by isolating a node using chaos-mesh.

```
./chaos/apply.bash
```

Eventually, we want running `./show.bash` again to show that there is a problem.

> HOWEVER

It will never show the problem. Since the plugin runs from within the DaemonSet
pod that is running on the node, while the plugin can detect the problem, it
cannot reach the api-server to update the node's status or publish an event.

This can be seen in the NPD logs:

`$ k logs -n kube-system -l app=node-problem-detector,nodeName=npd-test-worker --prefix --tail=-1`

```
[pod/node-problem-detector-8n5px/node-problem-detector] E0115 20:33:30.863102       1 plugin.go:185] Error in running plugin timeout "./custom-config/plugin-network_problem.sh"
[pod/node-problem-detector-8n5px/node-problem-detector] I0115 20:33:30.865559       1 custom_plugin_monitor.go:283] New status generated: &{Source:network-custom-plugin-monitor Events:[{Severity:info Timestamp:2025-01-15 20:33:30.865492196 +0000 UTC m=+155.020234873 Reason:ApiServerUnreachable Message:Node condition NetworkProblem is now: Unknown, reason: ApiServerUnreachable, message: "Timeout when running plugin \"./custom-config/plugin-network_problem.sh\": state -"}] Conditions:[{Type:NetworkProblem Status:Unknown Transition:2025-01-15 20:33:30.865492196 +0000 UTC m=+155.020234873 Reason:ApiServerUnreachable Message:Timeout when running plugin "./custom-config/plugin-network_problem.sh": state -}]}
[pod/node-problem-detector-8n5px/node-problem-detector] E0115 20:34:00.863103       1 plugin.go:185] Error in running plugin timeout "./custom-config/plugin-network_problem.sh"
[pod/node-problem-detector-8n5px/node-problem-detector] E0115 20:34:00.867591       1 event.go:368] "Unable to write event (may retry after sleeping)" err="Post \"https://10.96.0.1:443/api/v1/namespaces/default/events\": dial tcp 10.96.0.1:443: i/o timeout" event="&Event{ObjectMeta:{npd-test-worker.181af7eeb2052a5c  default    0 0001-01-01 00:00:00 +0000 UTC <nil> <nil> map[] map[] [] [] []},InvolvedObject:ObjectReference{Kind:Node,Namespace:,Name:npd-test-worker,UID:npd-test-worker,APIVersion:,ResourceVersion:,FieldPath:,},Reason:ApiServerUnreachable,Message:Node condition NetworkProblem is now: Unknown, reason: ApiServerUnreachable, message: \"Timeout when running plugin \\\"./custom-config/plugin-network_problem.sh\\\": state -\",Source:EventSource{Component:network-custom-plugin-monitor,Host:npd-test-worker,},FirstTimestamp:2025-01-15 20:33:30.865707612 +0000 UTC m=+155.020450289,LastTimestamp:2025-01-15 20:33:30.865707612 +0000 UTC m=+155.020450289,Count:1,Type:Normal,EventTime:0001-01-01 00:00:00 +0000 UTC,Series:nil,Action:,Related:nil,ReportingController:network-custom-plugin-monitor,ReportingInstance:npd-test-worker,}"
```

## Cleanup

Quick cleanup is to delete the kind cluster with `kind delete cluster -n npd-test`
