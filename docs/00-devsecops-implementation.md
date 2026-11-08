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

1. Pull request validation: compile, unit tests, coverage, code quality, secret/dependency/static security scans, Kubernetes schema checks, and OPA policy evaluation.
2. Main-branch release: build a container from the tested application, scan it, generate an SBOM, and publish an immutable commit-SHA tag to GitHub Container Registry (GHCR).
3. GitOps promotion: update the deployment configuration to the immutable image digest or commit-SHA tag; Argo CD reconciles the desired state.
4. Progressive delivery: Argo Rollouts shifts traffic only while Prometheus analysis passes.
5. Recovery: failed analysis aborts promotion and returns traffic to the stable ReplicaSet; operators use documented rollback procedures.

## Naming and environment conventions

- Kubernetes production namespace: `production` (canonical; workload and analysis resources must agree).
- Container image repository: `ghcr.io/<github-owner>/novapay`.
- Image identity: immutable Git commit SHA. Do not deploy `latest`.
- Application container port: `8080`.
- Health endpoint: `/actuator/health` (confirm actuator exposure/configuration before using it as a Kubernetes probe).
- Java runtime: Java 21; build system: Maven.

The actual GHCR owner, registry permissions, Kubernetes cluster, ingress/service mesh, Prometheus address, and Argo CD installation are environment-specific prerequisites. They must be supplied as repository or environment configuration; credentials must never be committed.

## Phase 1 — foundation

- Isolated branch: `feat/devsecops-phase-1-foundation`.
- Docker build context excludes local build output, IDE files, environment files, and secret material using `app/.dockerignore`.
- Dependabot checks Maven and GitHub Actions dependencies weekly.

## Phase 2 — CI quality and security

- Maven `clean verify` executes tests and generates a JaCoCo XML coverage report.
- The self-hosted SonarQube server performs analysis and the workflow waits for its Quality Gate result.
- CodeQL analyzes Java/Kotlin source code.
- Gitleaks scans repository history for exposed credentials.
- Trivy scans the repository filesystem for HIGH and CRITICAL vulnerabilities, misconfigurations, and secrets.
- Conftest evaluates the actual Kubernetes Rollout/Deployment pod template against the OPA workload policy.
- Kubernetes YAML syntax is parsed before policy evaluation.

### Self-hosted SonarQube repository configuration

Configure these GitHub repository settings under **Settings → Secrets and variables → Actions**:

| Setting | Type | Value |
|---|---|---|
| `SONAR_TOKEN` | Actions secret | User token generated in your self-hosted SonarQube server |
| `SONAR_HOST_URL` | Actions variable | Base URL of your SonarQube server, e.g. `https://sonarqube.example.com` |
| `SONAR_PROJECT_KEY` | Actions variable | Exact project key created in SonarQube |
| `SONAR_RUNNER_LABEL` | Optional Actions variable | GitHub Actions runner label that can reach SonarQube; defaults to `ubuntu-latest` |

Do not include a trailing path such as `/dashboard` in `SONAR_HOST_URL`; use the server base URL. Use HTTPS and keep the token in the secret store only. The workflow rejects a SonarCloud URL and fails clearly if the required settings are missing. It waits up to 300 seconds for the Quality Gate and fails the job when the gate fails.

**Network requirement:** the runner executing the SonarQube job must be able to resolve and connect to `SONAR_HOST_URL`. If the server is private/on-premises and not reachable from GitHub-hosted runners, register a suitably secured GitHub self-hosted runner inside the network (or provide an approved private connectivity path), then set `SONAR_RUNNER_LABEL` to one of that runner's labels. The runner must have Java 21, Maven-compatible network access, and outbound access to required Maven repositories/GitHub actions. Do not expose a private SonarQube server publicly just to make CI work.

The workflow uses the Maven SonarScanner plugin and passes the server URL, project key, and token at runtime. The token is not written to the repository or printed by the workflow.

### Current scope and limitations

- The workflow currently uses version tags for some third-party Actions. Before production use, pin every Action to a reviewed full commit SHA.
- Trivy filesystem scanning is not a substitute for a dedicated container-image scan; image scanning is part of Phase 3.
- YAML parsing is syntax validation, not full Kubernetes API-server schema validation. Add schema validation and CRD-aware checks before deployment.
- The current OPA policy enforces non-root execution, read-only root filesystem, non-privileged containers, and CPU/memory limits on Deployments and Argo Rollouts.
- CodeQL, SonarQube and vulnerability results depend on external services, server reachability, plugin compatibility, and their configured project/repository settings.

## Implementation phases

- Phase 1 — foundation: establish the isolated feature branch, repository conventions, Docker build-context hygiene, and implementation contract.
- Phase 2 — CI quality and security: real tests/coverage, self-hosted SonarQube quality gate, secret/dependency/SAST scans, Kubernetes validation, and OPA evaluation.
- Phase 3 — immutable artifact: Docker build, vulnerability scan, SBOM, provenance/signing, and GHCR publication.
- Phase 4 — GitOps and progressive delivery: reconcile Argo CD paths/namespaces/images and configure canary traffic routing and analysis.
- Phase 5 — operational verification: deploy to a real cluster, test health/metrics/rollback, and capture evidence.

## Acceptance criteria

A green GitHub Actions run is not proof of deployment. Each phase must report what was actually executed. Deployment is considered complete only after a real cluster has reconciled the release and a rollout has passed health and metric analysis.
