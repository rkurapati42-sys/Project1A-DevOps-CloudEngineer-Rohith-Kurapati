
-- EXPAND PHASE: Zero-downtime backward-compatible column expansion
ALTER TABLE customer_profiles ADD COLUMN encrypted_email BYTEA;
CREATE INDEX CONCURRENTLY idx_customer_encrypted_email ON customer_profiles (encrypted_email);

INSERT INTO schema_audit_log (migration_id, description, executed_by, phase)
VALUES ('V2.0', 'Expand: Add encrypted_email', current_user, 'EXPAND');
