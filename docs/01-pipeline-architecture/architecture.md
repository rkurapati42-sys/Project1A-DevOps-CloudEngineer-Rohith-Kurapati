# NovaPay CI/CD Pipeline Architecture

## Delivery stages

The single GitHub Actions workflow implements these stages:

1. **Source control** — pull requests to `main`, release pushes, and approved manual runs.
2. **Build, unit tests and API contract tests** — Maven Java 21 build, JUnit tests, HTTP contract checks, and JaCoCo coverage.
3. **Code quality** — self-hosted SonarQube Quality Gate. The job downloads the compiled Maven output and coverage report from the build job; it does not repeat `clean verify`.
4. **SAST** — CodeQL Java/Kotlin analysis.
5. **Secrets and dependency security** — Gitleaks full-history scan and Trivy filesystem scan.
6. **DAST** — OWASP ZAP passive baseline scan against the running NovaPay application, with an HTML report retained as an artifact.
7. **Kubernetes compliance** — YAML parsing, kubeconform schema validation where schemas are available, and Conftest/OPA policy checks.
8. **Container security and SBOM** — build the image from the tested JAR, scan with Trivy, and upload a CycloneDX SBOM.
9. **Release publication** — on a push to `main` only, publish a commit-SHA image to GHCR, attach BuildKit SBOM/provenance, and Cosign-sign and verify the immutable digest.

## Execution and cost controls

- Feature branch commits are validated through the open pull request. The workflow does not also run a second full pipeline for each feature-branch push.
- `workflow_dispatch` remains available for an explicit manual run.
- Maven tests/package execute once per workflow run. SonarQube, DAST, and container jobs reuse the tested build artifact.
- CodeQL retains its own instrumented compile because CodeQL must trace the compilation for source analysis.
- Container scanning and SBOM generation are mandatory prerequisites for the GHCR release job.
- GHCR publishing is restricted to `push` events on `main`; pull requests and feature branches never publish.

## Release and deployment boundary

The main-branch workflow publishes and signs the image; it does not claim a live Kubernetes deployment. Argo CD and Argo Rollouts require a configured cluster with the matching CRDs, Istio traffic routing, Prometheus metrics, and a verified immutable image reference. See the deployment strategy and runbook documents for operator validation.

## Target topology

```text
Developer -> Pull Request -> GitHub Actions
                              |
            +-----------------+------------------+
            |                 |                  |
         Maven/API          CodeQL         Gitleaks/Trivy
            |                 |                  |
        Build Artifact -> SonarQube             |
            |                                    |
         OWASP ZAP                         K8s + OPA
            |                                    |
            +-----------------+------------------+
                              |
                      Container Build
                              |
                     Trivy Image Scan
                              |
                       CycloneDX SBOM
                              |
                    main-only GHCR publish
                              |
                   Provenance + Cosign verify
                              |
                   Argo CD / Argo Rollouts
                              |
                   Istio + Prometheus analysis
```
