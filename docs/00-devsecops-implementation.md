# NovaPay DevSecOps Implementation Baseline

## Purpose

This document defines the implementation contract for the NovaPay assessment pipeline. Changes are developed on feature branches and merged to `main` only through a reviewed pull request after required checks pass.

## Repository ownership and source of truth

- Application source and Maven build: `app/`
- GitHub Actions entry point: `.github/workflows/main.yml`
- Kubernetes workload and rollout resources: `pipeline/k8s/`
- OPA policies: `pipeline/policies/`
- Argo CD application definition: `pipeline/argocd/`
- Operational and architecture documentation: `docs/` and `runbooks/`

There must be one active CI workflow. Do not add a second workflow under `pipeline/`.

## Target delivery flow

1. Pull request validation: compile, unit/API-contract tests, coverage, code quality, secret/dependency/static security scans, DAST baseline, Kubernetes schema checks, and OPA policy evaluation.
2. Main-branch release: reuse the tested Maven artifact, build and scan the container, generate an SBOM, and publish an immutable commit-SHA image to GHCR.
3. Supply-chain verification: attach BuildKit SBOM/provenance, sign the image digest with Cosign keyless OIDC, and verify the signature.
4. GitOps promotion: Argo CD reconciles `pipeline/k8s` from this repository. Replace the explicit release-image placeholder with the verified immutable GHCR digest through the approved release-promotion process.
5. Progressive delivery: Argo Rollouts shifts traffic through Istio while Prometheus analysis checks success rate and p99 latency.
6. Recovery: failed analysis aborts promotion and returns traffic to the stable ReplicaSet; operators use documented rollback procedures.

## Naming and environment conventions

- Kubernetes production namespace: `production`.
- Container image repository: `ghcr.io/rkurapati42-sys/novapay`.
- Image identity: immutable Git commit SHA or digest. Do not deploy `latest`.
- Application container port: `8080`.
- Health endpoints: `/actuator/health`, `/actuator/health/readiness`, and `/actuator/health/liveness`.
- Java runtime: Java 21; build system: Maven.

The actual Kubernetes cluster, Istio installation/gateway, Prometheus service, Argo CD installation, GHCR package visibility, and production approval controls are environment-specific prerequisites. They must be supplied and verified in the target environment; credentials must never be committed.

## Phase 1 — foundation

- Isolated feature branch and repository conventions.
- Docker build-context hygiene using `app/.dockerignore`.
- Dependabot checks Maven and GitHub Actions dependencies weekly.

## Phase 2 — CI quality and security

- Maven `clean verify` executes unit and API-contract tests and generates JaCoCo XML coverage.
- The build job uploads its compiled output, test classes, packaged JAR, and coverage report as a short-lived artifact.
- SonarQube downloads and reuses that build output. It runs only the Maven SonarScanner goal; it does not run `clean verify` a second time.
- CodeQL analyzes Java/Kotlin source code.
- Gitleaks scans full repository history.
- Trivy scans the repository filesystem for HIGH and CRITICAL vulnerabilities, misconfigurations, and secrets.
- OWASP ZAP performs a passive baseline DAST scan against the running application; the HTML report is retained as a workflow artifact.
- kubeconform validates known Kubernetes API schemas; Conftest evaluates the manifests against OPA workload policies.

### Self-hosted SonarQube repository configuration

Configure these GitHub repository settings under **Settings → Secrets and variables → Actions**:

| Setting | Type | Value |
|---|---|---|
| `SONAR_TOKEN` | Actions secret | User token generated in your self-hosted SonarQube server |
| `SONAR_HOST_URL` | Actions variable | Base URL of your SonarQube server |
| `SONAR_PROJECT_KEY` | Actions variable | Exact project key created in SonarQube |
| `SONAR_RUNNER_LABEL` | Optional Actions variable | Runner label that can reach SonarQube; defaults to `ubuntu-latest` |

The runner executing the SonarQube job must be able to resolve and connect to `SONAR_HOST_URL`. For a private server, use a secured self-hosted runner inside the network or approved private connectivity. Do not expose a private SonarQube server publicly. The token remains in GitHub Secrets and is never printed.

## Phase 3 — container and supply-chain security

- Container build consumes the already-tested Maven JAR rather than rebuilding it.
- Trivy blocks HIGH/CRITICAL image findings under the configured policy.
- CycloneDX SBOM is uploaded for every successful feature/PR image scan.
- Main-branch release publishes a commit-SHA tag to GHCR.
- BuildKit attaches SBOM and provenance; Cosign keyless signing and verification use GitHub Actions OIDC.
- Feature-branch and pull-request runs do not publish images.

See `docs/09-container-security-ghcr.md` for release details.

## Phase 4 — GitOps and progressive delivery

- Argo CD points to this repository's `pipeline/k8s` directory and the canonical `production` namespace.
- Kustomize groups the Namespace, Rollout, AnalysisTemplate, Services, and Istio VirtualService.
- Argo Rollouts uses stable/canary Services and Istio traffic weights.
- Prometheus analysis checks success rate and p99 latency before traffic progresses.
- The rollout manifest is pinned to the verified immutable GHCR digest for the current release. Confirm cluster prerequisites, registry pull access, and Cosign policy before Argo CD sync; update the digest through a reviewed release change for subsequent versions.

## Phase 5 — operational verification

A real cluster must have Argo CD, the Argo Rollouts controller, Istio, and Prometheus installed and configured. Verify reconciliation, image pull access, canary traffic, analysis metrics, health probes, and rollback before claiming a deployment is complete.

## Current limitations and production hardening

- Third-party GitHub Actions are referenced by version tags; pin reviewed full commit SHAs before production use.
- kubeconform skips missing schemas for CRDs such as Argo Rollouts and Istio; validate those resources against the exact installed CRD versions in the target cluster.
- The ZAP baseline scan is passive and is not a substitute for authenticated active testing or a full penetration test.
- The Argo CD Application and rollout resources are configuration, not proof of a live deployment.
- The assessment app's payment service is a demonstration implementation, not a real payment processor.

## Acceptance criteria

A green workflow proves the checks executed for that commit. GHCR publication is complete only after the main-branch publish job passes and the digest/signature can be verified. Deployment is complete only after a real cluster reconciles the release and the rollout passes health and metric analysis.
