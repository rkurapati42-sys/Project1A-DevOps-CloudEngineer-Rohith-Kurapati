# NovaPay Zero-Downtime CI/CD Pipeline Assessment

## Project
NovaPay Digital Bank — secure zero-downtime CI/CD platform.

## Objectives
- Automated CI/CD.
- Zero-downtime deployments.
- Blue-green and canary strategies.
- Compliance and security gates.
- Expand-contract database migrations.
- Controlled environment promotion.
- Automated rollback.
- Production observability.
- Complete audit evidence.

## Architecture
~~~text
Developer
   |
GitHub
   |
CI/CD
   +--> Build & Test
   +--> Quality
   +--> SAST / Dependency / Container Security
   +--> SBOM / Provenance / Signing
   +--> Compliance Gates
   |
Artifact Registry
   |
DEV -> STAGING -> PRE-PROD -> PROD
                         |
                  Blue-Green / Canary
                         |
              Prometheus / Grafana
~~~

## Key Documents
- [Pipeline Architecture](docs/01-pipeline-architecture/architecture.md)
- [Deployment Strategies](docs/02-deployment-strategies/strategies.md)
- [Compliance Gates](docs/03-compliance-gates/gates.md)
- [Database Migration](docs/04-database-migration/migration.md)
- [Environment Promotion](docs/05-environment-promotion/promotion.md)
- [Rollback Specification](docs/06-rollback-specification/rollback.md)
- [Runbook](docs/07-runbook-playbook/runbook.md)
- [Observability](docs/08-observability/observability.md)

## Production Principles
- No 'latest' production image tags.
- Use SemVer + Git SHA.
- Sign release images.
- Verify signatures at admission.
- Preserve immutable artifact provenance.
- Never expose secrets in Git.
- Roll back application traffic without destructive DB rollback.
- Retain deployment and incident evidence.