# NovaPay Environment Promotion

## Environment Flow
DEV -> STAGING -> PRE-PROD -> PRODUCTION

## Promotion Criteria
### DEV
- Build succeeds.
- Unit tests pass.
- Basic security checks pass.
- Developer validation complete.

### STAGING
- CI pipeline passes.
- Integration and contract tests pass.
- SAST and dependency checks pass.
- Deployment health checks pass.
- Smoke tests pass.

### PRE-PROD
- Production-like configuration validated.
- DAST passes.
- Compliance gates pass.
- Database compatibility validated.
- Performance and rollback tests completed.
- Release approval obtained.

### PRODUCTION
- All mandatory compliance gates pass.
- Artifact provenance is available.
- Image is signed.
- Production approval is recorded.
- Deployment strategy is selected.
- Rollback plan is confirmed.
- Monitoring is ready.

## Approval and RBAC
| Environment | Promotion Control |
|---|---|
| DEV | Developer |
| STAGING | Developer / QA |
| PRE-PROD | QA / Release Owner |
| PRODUCTION | Authorized Release Owner + required approver |

Production deployment must not be controlled by an unrestricted developer account.

## Configuration Hierarchy
Application Defaults -> Environment Configuration -> Secret Management -> Runtime Overrides

Secrets must never be committed to Git.

## Data Management
- DEV: synthetic data.
- STAGING: controlled test data.
- PRE-PROD: masked production-like data.
- PROD: live data with strict access control.
- Production data must not be copied to lower environments without approved masking.

## Immutable Artifact Promotion
The same immutable artifact is promoted between environments rather than rebuilding separate binaries. Artifact identity remains traceable to Git SHA, SemVer and SBOM.

## Success Criteria
Every promotion has automated evidence, required approval, health validation and an available rollback path.