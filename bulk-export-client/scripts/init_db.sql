CREATE TABLE IF NOT EXISTS payer_data_exchange_requests (
    request_id VARCHAR(36) PRIMARY KEY,
    member_id VARCHAR(255) NOT NULL,
    payer_id VARCHAR(255) NOT NULL,
    old_payer_name VARCHAR(255) NOT NULL,
    old_payer_state VARCHAR(255) NOT NULL,
    old_coverage_id VARCHAR(255),
    coverage_start_date DATE,
    coverage_end_date DATE,
    consent_status VARCHAR(50) DEFAULT 'PENDING',
    bulk_data_sync_status VARCHAR(50) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payers (
  id VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  state VARCHAR(50) DEFAULT NULL,
  fhir_server_url VARCHAR(500) NOT NULL,
  app_client_id VARCHAR(255) NOT NULL,
  app_client_secret VARCHAR(255) NOT NULL,
  token_url VARCHAR(255) NOT NULL,
  scopes TEXT,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);

