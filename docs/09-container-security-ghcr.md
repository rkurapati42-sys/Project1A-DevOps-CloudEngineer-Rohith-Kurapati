# Phase 3 — Container Security and GHCR Release

## Objective

Produce a reproducible NovaPay container, block publication when the image has HIGH or CRITICAL vulnerabilities, generate an SBOM, and publish an immutable image to GitHub Container Registry (GHCR) with build provenance and a keyless signature.

## Image identity

- Registry: `ghcr.io`
- Image repository: `ghcr.io/<github-owner>/novapay`
- Release tag: full Git commit SHA (`github.sha`)
- Deployment reference: prefer the published image digest (`ghcr.io/<owner>/novapay@sha256:...`)
- Do not deploy `latest`.

## Pull requests and feature branches

1. Maven build, tests, and JaCoCo coverage execute once in the build job.
2. The compiled output and packaged JAR are uploaded as a short-lived workflow artifact.
3. SonarQube, DAST, and container build jobs reuse that artifact instead of repeating the Maven package/test lifecycle.
4. The local image is scanned with Trivy for HIGH and CRITICAL vulnerabilities, misconfigurations, and secrets. Unfixed findings are ignored; matching findings fail the job.
5. A CycloneDX SBOM is generated from the built image and uploaded as a 30-day artifact.
6. No image is published to GHCR from pull requests or feature branches.

## Main branch release

After container-security succeeds on a push to `main`:

1. Download the exact tested Maven artifact from the same workflow run.
2. Authenticate to GHCR using the workflow's short-lived `GITHUB_TOKEN`.
3. Publish the image tagged with the full Git commit SHA.
4. Enable BuildKit SBOM and provenance attestations.
5. Sign the published image digest using Cosign keyless signing backed by GitHub Actions OIDC.
6. Verify the signature against the GitHub Actions OIDC issuer and this repository's workflow identity.
7. Record both the commit-SHA tag and immutable digest in the job log.

## Required GitHub Actions permissions

The publishing job declares only the permissions it needs:

- `contents: read` for checkout.
- `packages: write` to publish to GHCR.
- `id-token: write` for keyless OIDC signing.
- `attestations: write` for GitHub build attestations.

The repository's Actions settings must permit the declared token permissions. Review package visibility and repository linkage in GitHub after the first main-branch publication.

## Verification checklist

- [ ] Maven tests and JaCoCo report pass.
- [ ] SonarQube reuses build output and passes its Quality Gate.
- [ ] DAST baseline scan completes and report is uploaded.
- [ ] Container image builds from the tested Maven JAR.
- [ ] Trivy image scan passes the configured severity gate.
- [ ] CycloneDX SBOM is uploaded and downloadable.
- [ ] Main-branch run publishes `ghcr.io/<owner>/novapay:<full-commit-sha>`.
- [ ] BuildKit provenance and SBOM attestations are generated.
- [ ] Cosign signing and signature verification complete successfully.
- [x] The logged digest matches the published GHCR manifest (`sha256:37f55d562724ebf13eef6ef2595a6187d434a322f59161309b4a07299e6f5f48`).

## Security and scope notes

- Feature-branch workflow success proves build and scan behavior, not registry publication.
- A green publishing job proves image publication/signing, not Kubernetes deployment.
- The rollout manifest is pinned to the verified immutable GHCR digest for main release commit `57c4cb90a7a4744c8512cc7105fa7d1213744c2f`. Confirm the target cluster can pull the package and verify its Cosign signature before Argo CD sync.
- The current workflow uses version tags for third-party Actions. Pin them to reviewed full commit SHAs before production use.


## Verified release record — 2026-11-08

- Main commit: `57c4cb90a7a4744c8512cc7105fa7d1213744c2f`
- Image tag: `ghcr.io/rkurapati42-sys/novapay:57c4cb90a7a4744c8512cc7105fa7d1213744c2f`
- Immutable image: `ghcr.io/rkurapati42-sys/novapay@sha256:37f55d562724ebf13eef6ef2595a6187d434a322f59161309b4a07299e6f5f48`
- Main pipeline run: [42440898981](https://github.com/rkurapati42-sys/Project1A-DevOps-CloudEngineer-Rohith-Kurapati/actions/runs/42440898981)
- The publishing job completed successfully, including Cosign signing and verification.
- This release record does not assert that a Kubernetes cluster has been deployed or synchronized.
