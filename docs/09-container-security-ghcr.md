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
- [ ] The logged digest matches the published GHCR manifest.

## Security and scope notes

- Feature-branch workflow success proves build and scan behavior, not registry publication.
- A green publishing job proves image publication/signing, not Kubernetes deployment.
- The Kubernetes rollout image value is an explicit release placeholder and must be replaced with the verified immutable digest before Argo CD sync.
- The current workflow uses version tags for third-party Actions. Pin them to reviewed full commit SHAs before production use.
