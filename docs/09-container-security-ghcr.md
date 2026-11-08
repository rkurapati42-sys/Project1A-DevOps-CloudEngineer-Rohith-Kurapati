# Phase 3 — Container Security and GHCR Release

## Objective

Produce a reproducible NovaPay container, block publication when the image has HIGH or CRITICAL vulnerabilities, generate an SBOM, and publish an immutable image to GitHub Container Registry (GHCR) with build provenance and a keyless signature.

## Image identity

- Registry: `ghcr.io`
- Image repository: `ghcr.io/<github-owner>/novapay`
- Release tag: full Git commit SHA (`github.sha`)
- Deployment reference: prefer the published image digest (`ghcr.io/<owner>/novapay@sha256:...`)
- Do not deploy `latest`.

## Pipeline behavior

### Pull requests and feature branches

1. Wait for the Phase 2 quality and security jobs.
2. Build the Maven application with Java 21.
3. Build the Docker image from `app/Dockerfile`.
4. Scan the local image with Trivy for HIGH and CRITICAL vulnerabilities, misconfigurations, and secrets. Unfixed findings are ignored; any remaining matching finding fails the job.
5. Generate a CycloneDX SBOM from the image and upload it as a 30-day workflow artifact.
6. Do not publish to GHCR from pull requests or feature branches.

### Main branch release

After the container-security job succeeds on a push to `main`:

1. Build the application and container again from the exact checked-out commit.
2. Authenticate to GHCR using the workflow's short-lived `GITHUB_TOKEN`; no personal access token is stored.
3. Publish the image tagged with the full Git commit SHA.
4. Enable BuildKit SBOM and provenance attestations.
5. Sign the published image digest using Cosign keyless signing backed by GitHub Actions OIDC.
6. Record both the commit-SHA tag and immutable digest in the job log.

## Required GitHub Actions permissions

The publishing job declares only the permissions it needs:

- `contents: read` to check out source.
- `packages: write` to publish to GHCR.
- `id-token: write` for keyless OIDC signing.
- `attestations: write` for GitHub build attestations.

The repository's Actions setting for workflow permissions must permit the declared token permissions. The first package publication may create a private GHCR package; review package visibility and repository linkage in GitHub before sharing or deploying it.

## Verification checklist

- [ ] Phase 2 jobs pass.
- [ ] Container image builds from the Maven artifact.
- [ ] Trivy image scan passes the configured severity gate.
- [ ] CycloneDX SBOM is uploaded and downloadable from the workflow run.
- [ ] Main-branch run publishes `ghcr.io/<owner>/novapay:<full-commit-sha>`.
- [ ] BuildKit provenance and SBOM attestations are generated.
- [ ] Cosign keyless signing completes successfully.
- [ ] The digest recorded in the logs matches the published GHCR manifest.

## Security and scope notes

- The feature-branch workflow intentionally does not publish images. GHCR publication is restricted to a successful main-branch push.
- A green feature-branch run proves build and scan behavior, not registry publication.
- A green publishing job proves image publication/signing, not Kubernetes deployment.
- The existing Dockerfile expects `app/target/novapay-1.0.0.jar`; the workflow runs Maven packaging before each Docker build.
- Action references are currently version tags. Before production use, review and pin third-party Actions to full commit SHAs.
