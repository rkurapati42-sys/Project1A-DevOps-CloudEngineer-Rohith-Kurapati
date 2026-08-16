
package kubernetes.admission

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("RBI/PCI-DSS Gate Failure: Privileged containers are prohibited (%v)", [container.name])
}

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Resource Limit Failure: Memory limit is mandatory for container (%v)", [container.name])
}
package kubernetes.admission

# Deny privileged containers - RBI IT Risk Governance §4.3 & PCI-DSS Req 6.2
deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("COMPLIANCE VIOLATION (RBI §4.3 / PCI-DSS 6.2): Privileged container execution is blocked for container '%v'.", [container.name])
}

# Enforce non-root execution
deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.runAsNonRoot != true
    msg := sprintf("SECURITY VIOLATION: Container '%v' must set runAsNonRoot to true.", [container.name])
}

# Mandatory CPU and Memory Resource Limits
deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("GOVERNANCE VIOLATION: Memory limit must be declared for container '%v'.", [container.name])
}

# Require Signed Image Verification
deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not startswith(container.image, "artifactory.novapay.internal/")
    msg := sprintf("SUPPLY CHAIN VIOLATION: Image '%v' is not from an approved trusted registry.", [container.image])
}
