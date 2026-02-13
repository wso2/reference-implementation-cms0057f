CREATE TABLE IF NOT EXISTS payer_data_exchange_requests (
    request_id VARCHAR(36) PRIMARY KEY,
    member_id VARCHAR(255) NOT NULL,
    old_payer_name VARCHAR(255) NOT NULL,
    old_payer_state VARCHAR(255) NOT NULL,
    old_coverage_id VARCHAR(255),
    coverage_start_date DATE,
    coverage_end_date DATE,
    consent_status VARCHAR(50) DEFAULT 'PENDING',
    bulk_data_sync_status VARCHAR(50) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
