
# NovaPay Compliance Gates

## Objective

NovaPay compliance gates prevent insecure, non-compliant, or unauditable releases from reaching production.

All production deployments must pass the mandatory security, quality, container, infrastructure, policy, and audit gates before traffic is shifted.

## Compliance Gate Summary

| Gate | Requirement | Threshold | Action on Failure |
|---|---|---:|---|
| Unit Test Gate | Automated tests | 100% pass | Stop pipeline |
| Code Quality Gate | SonarQube quality | Quality Gate = PASS | Stop pipeline |
| SAST Gate | Critical/High vulnerabilities | 0 Critical, 0 High | Stop pipeline |
| Dependency Gate | Vulnerable dependencies | 0 Critical, 0 High | Stop pipeline |
| Container Scan Gate | Image vulnerabilities | 0 Critical, 0 High | Stop pipeline |
| Secret Detection Gate | Exposed credentials | 0 secrets | Stop pipeline |
| SBOM Gate | Software inventory | SBOM generated | Stop pipeline |
| Image Signing Gate | Artifact authenticity | Signature required | Stop pipeline |
| IaC/Policy Gate | Kubernetes/IaC compliance | 100% mandatory policies pass | Stop pipeline |
| DAST Gate | Runtime security testing | 0 Critical/High findings | Stop pipeline |

## Gate 1 — Unit Test

All automated unit tests must complete successfully.

### Threshold

- Test failures: `0`
- Test errors: `0`

### Failure Action

The pipeline stops and the artifact cannot proceed to deployment.

### Remediation

Developers must correct the failing test or application defect and create a new build.

## Gate 2 — Code Quality

Static code quality analysis is performed before deployment.

### Threshold

- SonarQube Quality Gate: `PASS`
- New Critical issues: `0`
- New Blocker issues: `0`

### Failure Action

Production deployment is blocked.

### Remediation

The development team reviews the SonarQube findings and fixes the affected code.

## Gate 3 — SAST

Static Application Security Testing identifies security vulnerabilities in source code.

### Threshold

- Critical vulnerabilities: `0`
- High vulnerabilities: `0`

### Failure Action

The release is rejected.

### Remediation

The vulnerable code must be corrected and the security scan repeated.

## Gate 4 — Dependency Scanning

Third-party dependencies are scanned for known vulnerabilities.

### Threshold

- Critical vulnerabilities: `0`
- High vulnerabilities: `0`

### Failure Action

The build cannot proceed to production.

### Remediation

Upgrade, replace, or remove the affected dependency and regenerate the build.

## Gate 5 — Container Image Scanning

The final NovaPay container image must be scanned before deployment.

### Threshold

- Critical vulnerabilities: `0`
- High vulnerabilities: `0`
- Image must have an SBOM.
- Production images must not use the `latest` tag.

### Failure Action

The image is rejected.

### Remediation

Rebuild the image using patched dependencies or a secure base image.

## Gate 6 — Secret Detection

Source code, configuration, and container contents are checked for exposed credentials.

### Threshold

- Hard-coded secrets: `0`
- Private keys: `0`
- Production credentials: `0`

### Failure Action

The pipeline immediately stops.

### Remediation

Remove the secret, rotate compromised credentials, and store secrets using the approved secret-management mechanism.

## Gate 7 — SBOM and Artifact Provenance

Every production container must have a Software Bill of Materials and traceable build provenance.

### Requirements

- SBOM generated for every production image.
- Image linked to the Git commit.
- Image tagged using SemVer and Git SHA.
- Build metadata retained as audit evidence.
- Production must never deploy an untraceable artifact.

Example:

```text
novapay:1.2.3-8c6c5b9
## Gate 8 — Image Signing

Production container images must be cryptographically signed.

### Requirement

Images must be signed using Cosign or an equivalent approved signing mechanism.

Unsigned images must never be deployed to production.

### Admission Control

An OPA or Kyverno admission policy must reject unsigned production images.

```text
Developer Commit
      |
     Build
      |
Container Image
      |
    Sign
      |
Admission Controller
   /           \
Signed        Unsigned
  |              |
Allow           Reject

