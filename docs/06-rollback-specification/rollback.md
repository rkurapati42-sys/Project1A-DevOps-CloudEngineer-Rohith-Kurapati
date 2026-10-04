# NovaPay Rollback Specification

## Rollback Categories

### Category A — Immediate (<60 seconds)
- HTTP 5xx >5% for 60 seconds.
- Three consecutive health-check failures.
- OOM kills.
- CrashLoopBackOff.
- Database connection pool exhaustion.

### Category B — Escalated (<15 minutes)
- p99 latency >2x baseline for 5 minutes.
- Error-budget burn >10x for 10 minutes.
- Transaction success rate drops >2%.
- CPU >90% for 5 minutes.
- Memory >85% for 5 minutes.

### Category C — Manual
- Functional defects.
- Business-rule errors.
- Data-quality problems.
- Customer-impacting issues not captured by automated thresholds.

## Eight-Step Workflow
1. Detect and classify.
2. Freeze deployment progression.
3. Confirm last known healthy release.
4. Stop/reverse traffic to failed release.
5. Route traffic to healthy version.
6. Validate health, errors, latency and transactions.
7. Confirm customer impact has stopped.
8. Record evidence and begin RCA.

## Blue-Green Rollback
Switch production traffic from the failed environment to the last known healthy environment.

## Canary Rollback
Stop progression and return traffic to the stable version.

## Post-Rollback Verification
Verify HTTP 5xx, readiness/liveness, p99 latency, transaction success, CPU, memory, database connections, customer functionality and alert status.

## Database Safety
Destructive database rollback must not be automatic. Expand-contract migrations preserve compatibility so application rollback can occur without immediately reverting the expanded schema.

## Evidence
Record release version, Git SHA, trigger, detection time, rollback times, metrics before/after, operator, approver, customer impact and RCA reference.