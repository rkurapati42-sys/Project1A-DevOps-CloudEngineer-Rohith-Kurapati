package novapay

import future.keywords.in

default allow = false

# Allow deployment only if all compliance checks pass
allow {
    not runs_as_root
    has_resource_limits
    has_read_only_root_fs
    no_privileged_containers
}

# 1. Prevent containers from running as root (PCI-DSS 2.2.4)
runs_as_root {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.runAsNonRoot != true
}

# 2. Require CPU and Memory limits to prevent DoS (PCI-DSS 6.4.1)
has_resource_limits {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.resources.limits.cpu
    container.resources.limits.memory
}

# 3. Enforce read-only root filesystem (RBI Master Direction Sec 5.1)
has_read_only_root_fs {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.readOnlyRootFilesystem == true
}

# 4. Disallow privileged mode execution
no_privileged_containers {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.privileged == true
}
