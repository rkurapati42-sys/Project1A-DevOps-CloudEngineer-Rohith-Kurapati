-- MIGRATE PHASE: Batch backfill with throttling
DO $$
DECLARE
    batch_size INT := 1000;
    batch_count INT;
BEGIN
    LOOP
        UPDATE customer_profiles
        SET encrypted_email = pgp_sym_encrypt(email, current_setting('app.encryption_key'))
        WHERE encrypted_email IS NULL
        AND id IN (
            SELECT id FROM customer_profiles
            WHERE encrypted_email IS NULL
            LIMIT batch_size
            FOR UPDATE SKIP LOCKED
        );
        GET DIAGNOSTICS batch_count = ROW_COUNT;
        EXIT WHEN batch_count = 0;
        PERFORM pg_sleep(0.1); -- Throttling to prevent DB connection pool starvation
    END LOOP;
END $$;
