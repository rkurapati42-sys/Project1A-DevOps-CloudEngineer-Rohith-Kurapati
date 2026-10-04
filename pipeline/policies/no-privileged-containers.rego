package kubernetes.admission

# Deny privileged containers - RBI / PCI-DSS
deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("COMPLIANCE VIOLATION: privileged container '%v' is prohibited.", [container.name])
}

# Enforce non-root execution
deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.runAsNonRoot != true
    msg := sprintf("SECURITY VIOLATION: container '%v' must set runAsNonRoot=true.", [container.name])
}

# Mandatory CPU and memory limits
deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("GOVERNANCE VIOLATION: CPU limit is mandatory for '%v'.", [container.name])
}

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("GOVERNANCE VIOLATION: memory limit is mandatory for '%v'.", [container.name])
}

# Approved trusted registry check
deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not startswith(container.image, "artifactory.novapay.internal/")
    msg := sprintf("SUPPLY CHAIN VIOLATION: image '%v' is not from the approved trusted registry.", [container.image])
}