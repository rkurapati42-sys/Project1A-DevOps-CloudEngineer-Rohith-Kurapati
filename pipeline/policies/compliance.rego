package main

import rego.v1

# Apply workload controls to Kubernetes Deployments and Argo Rollouts.
workload if {
    input.kind == "Deployment"
}

workload if {
    input.kind == "Rollout"
}

containers := object.get(
    object.get(object.get(input, "spec", {}), "template", {}),
    "spec",
    {},
).containers

deny contains msg if {
    workload
    some container in containers
    object.get(object.get(container, "securityContext", {}), "runAsNonRoot", false) != true
    msg := sprintf("%s: container %q must set securityContext.runAsNonRoot=true", [input.kind, container.name])
}

deny contains msg if {
    workload
    some container in containers
    object.get(object.get(container, "securityContext", {}), "readOnlyRootFilesystem", false) != true
    msg := sprintf("%s: container %q must set securityContext.readOnlyRootFilesystem=true", [input.kind, container.name])
}

deny contains msg if {
    workload
    some container in containers
    object.get(object.get(container, "securityContext", {}), "privileged", false) == true
    msg := sprintf("%s: container %q must not run in privileged mode", [input.kind, container.name])
}

deny contains msg if {
    workload
    some container in containers
    not object.get(object.get(container, "resources", {}), "limits", {}).cpu
    msg := sprintf("%s: container %q must define a CPU limit", [input.kind, container.name])
}

deny contains msg if {
    workload
    some container in containers
    not object.get(object.get(container, "resources", {}), "limits", {}).memory
    msg := sprintf("%s: container %q must define a memory limit", [input.kind, container.name])
}
