CREATE TABLE IF NOT EXISTS payers (
  id VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  address VARCHAR(500) DEFAULT NULL,
  state VARCHAR(50) DEFAULT NULL,
  fhir_server_url VARCHAR(500) NOT NULL,
  app_client_id VARCHAR(255) NOT NULL,
  app_client_secret VARCHAR(255) NOT NULL,
  smart_config_url VARCHAR(255) NOT NULL,
  scopes TEXT,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS payer_data_exchange_requests (
    request_id VARCHAR(36) PRIMARY KEY,
    member_id VARCHAR(255) NOT NULL,
    payer_id VARCHAR(255) NOT NULL,
    old_coverage_id VARCHAR(255),
    coverage_start_date DATE,
    coverage_end_date DATE,
    consent_status VARCHAR(50) DEFAULT 'PENDING',
    bulk_data_sync_status VARCHAR(50) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (payer_id) REFERENCES payers(id)
);

-- Create index on email for faster lookups
CREATE INDEX idx_payers_email ON payers(email);

-- Create index on state for filtering
CREATE INDEX idx_payers_state ON payers(state);

INSERT INTO payers (id, name, email, state, fhir_server_url, app_client_id, app_client_secret, smart_config_url, address)
VALUES 
('PA120h2', 'Horizon Blue Cross', 'api-support@horizon.com', 'NJ', 'https://fhir.horizon.com/r4', 'cid_9988', 'sec_4455', 'https://fhir.horizon.com/.well-known/smart-configuration', '3 Penn Plaza East, Newark, NJ'),
('XT120b2', 'Kaiser Permanente', 'dev-portal@kp.org', 'CA', 'https://fhir.kaiser.com/r4', 'cid_1122', 'sec_3344', 'https://fhir.kaiser.com/.well-known/smart-configuration', '1 Kaiser Plaza, Oakland, CA'),
('YH235n1', 'Aetna Better Health', 'fhir-help@aetna.com', 'TX', 'https://api.aetna.com/fhir/v1', 'cid_5566', 'sec_7788', 'https://api.aetna.com/.well-known/smart-configuration', '151 Farmington Ave, Hartford, CT');

INSERT INTO payer_data_exchange_requests 
(request_id, member_id, payer_id, old_coverage_id, coverage_start_date, coverage_end_date, consent_status)
VALUES 
-- Patient 002 & 003 coming from Horizon (NJ)
(UUID(), 'patient-002', 'PA120h2', 'COV-99001', '2023-01-01', '2023-12-31', 'COMPLETED'),
(UUID(), 'patient-003', 'PA120h2', 'COV-99002', '2022-06-15', '2023-06-14', 'PENDING'),

-- Patient 004 & 005 coming from Kaiser (CA)
(UUID(), 'patient-004', 'XT120b2', 'KP-88221', '2023-01-01', NULL, 'COMPLETED'),
(UUID(), 'patient-005', 'XT120b2', 'KP-88225', '2024-01-01', NULL, 'PENDING'),

-- Patient 006 coming from Aetna (TX)
(UUID(), 'patient-006', 'YH235n1', 'AET-112233', '2021-01-01', '2022-12-31', 'COMPLETED');
