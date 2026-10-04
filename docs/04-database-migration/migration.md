# NovaPay Database Migration Strategy

## Objective

NovaPay uses an Expand-Contract migration pattern to support zero-downtime releases and backward compatibility between application versions.

## Migration Pattern

~~~text
Expand -> Migrate/Backfill -> Deploy Compatible Application -> Validate -> Contract
~~~

The old and new application versions must operate safely against the database during the transition.

## Phase 1 — Expand

'V2.0__expand_add_encrypted_email.sql':

- Adds nullable 'encrypted_email BYTEA'.
- Creates an index concurrently.
- Records the migration in the schema audit log.
- Does not remove or rename the existing column.

## Phase 2 — Migrate / Backfill

'V2.1__migrate_backfill_encrypted_email.sql':

- Backfills existing records in batches.
- Uses 'FOR UPDATE SKIP LOCKED' to reduce contention.
- Uses throttling between batches.
- Leaves the original 'email' column available for backward compatibility.

## Phase 3 — Application Compatibility

- Version N can continue reading the legacy column.
- Version N+1 can read/write the new encrypted column.
- Dual-read/dual-write logic is used when required.
- No deployment depends on an immediately removed database field.

## Phase 4 — Validate

Before contract:

- Verify row counts and null counts.
- Verify encryption/decryption behavior.
- Verify application transaction success.
- Verify database CPU, latency and connection utilization.
- Confirm old and new application versions remain compatible.

## Phase 5 — Contract

The legacy column is removed only after:

1. All production application instances use the new schema.
2. Backfill is complete.
3. Validation is successful.
4. Rollback window has expired.
5. Change approval is recorded.

## PostgreSQL Example

~~~sql
ALTER TABLE customer_profiles
ADD COLUMN encrypted_email BYTEA;

CREATE INDEX CONCURRENTLY idx_customer_encrypted_email
ON customer_profiles (encrypted_email);
~~~

Backfill must be performed in controlled batches rather than one unrestricted transaction.

## pgroll

pgroll may be used to manage schema changes using an expand-contract approach.

Required controls:

- Version-controlled migration definitions.
- Forward migration validation.
- Backward-compatible transition.
- Application compatibility during rollout.
- Explicit completion of the contract phase.
- Migration audit records.

## Compatibility Matrix

| Application | Database Schema | Status |
|---|---|---|
| Version N | Old schema | Supported |
| Version N | Expanded schema | Supported |
| Version N+1 | Expanded schema | Supported |
| Version N+1 | Backfilled schema | Supported |
| Version N+1 | Contracted schema | Supported after validation |
| Version N | Contracted schema | Not supported |

## Rollback

Before the contract phase:

1. Stop migration progression.
2. Keep the expanded schema.
3. Route traffic to the previous application version if required.
4. Preserve the legacy column.
5. Investigate and remediate the migration issue.
6. Resume only after compatibility validation.

The expanded schema should not be destructively removed during an incident.

## Database Governance

Every production migration must have:

- Change identifier.
- Migration version.
- Owner.
- Approval record.
- Execution timestamp.
- Audit record.
- Validation evidence.
- Rollback or recovery procedure.

## Zero-Downtime Success Criteria

- No application downtime.
- No destructive schema change during the expand phase.
- Old and new application versions remain compatible.
- Backfill is throttled.
- Database health remains within approved limits.
- Contract occurs only after successful validation.
