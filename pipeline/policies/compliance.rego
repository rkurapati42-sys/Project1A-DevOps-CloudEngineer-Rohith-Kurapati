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
    object.get(object.get(object.get(input, "spec", {}), "template", {}), "spec", {}),
    "containers",
    [],
)

limits(container) := object.get(
    object.get(container, "resources", {}),
    "limits",
    {},
)

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
    object.get(object.get(container, "securityContext", {}), "allowPrivilegeEscalation", true) != false
    msg := sprintf("%s: container %q must disable privilege escalation", [input.kind, container.name])
}

deny contains msg if {
    workload
    some container in containers
    not object.get(limits(container), "cpu", "")
    msg := sprintf("%s: container %q must define a CPU limit", [input.kind, container.name])
}

deny contains msg if {
    workload
    some container in containers
    not object.get(limits(container), "memory", "")
    msg := sprintf("%s: container %q must define a memory limit", [input.kind, container.name])
}

deny contains msg if {
    workload
    some container in containers
    not startswith(object.get(container, "image", ""), "ghcr.io/rkurapati42-sys/novapay:")
    msg := sprintf("%s: container %q must use the approved NovaPay GHCR image", [input.kind, container.name])
}

deny contains msg if {
    workload
    some container in containers
    endswith(object.get(container, "image", ""), ":latest")
    msg := sprintf("%s: container %q must not use the latest image tag", [input.kind, container.name])
}

deny contains msg if {
    workload
    some container in containers
    not object.get(container, "readinessProbe", null)
    msg := sprintf("%s: container %q must define a readiness probe", [input.kind, container.name])
}

deny contains msg if {
    workload
    some container in containers
    not object.get(container, "livenessProbe", null)
    msg := sprintf("%s: container %q must define a liveness probe", [input.kind, container.name])
}
