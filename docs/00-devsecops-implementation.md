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

## Security principles

- Pin third-party GitHub Actions to full commit SHAs before treating the workflow as production-hardened.
- Grant the minimum required GitHub token permissions per job.
- Use GitHub OIDC for cloud authentication where supported; avoid long-lived cloud keys.
- Never place secrets in workflow files, Docker build arguments, image layers, or manifests.
- Fail closed on secret, dependency, image, policy, and rollout-analysis violations.
- Generate and retain provenance and SBOM evidence for every released image.

## Implementation phases

- Phase 1 — foundation: establish the isolated feature branch, repository conventions, Docker build-context hygiene, and implementation contract.
- Phase 2 — CI quality and security: real tests/coverage, SonarQube quality gate, secret/dependency/SAST scans, Kubernetes validation, and OPA evaluation.
- Phase 3 — immutable artifact: Docker build, vulnerability scan, SBOM, provenance/signing, and GHCR publication.
- Phase 4 — GitOps and progressive delivery: reconcile Argo CD paths/namespaces/images and configure canary traffic routing and analysis.
- Phase 5 — operational verification: deploy to a real cluster, test health/metrics/rollback, and capture evidence.

## Acceptance criteria

A green GitHub Actions run is not proof of deployment. Each phase must report what was actually executed. Deployment is considered complete only after a real cluster has reconciled the release and a rollout has passed health and metric analysis.
