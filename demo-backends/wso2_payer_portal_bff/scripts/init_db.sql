CREATE TABLE pa_requests (
    request_id        VARCHAR(36)   NOT NULL,
    response_id       VARCHAR(36)   UNIQUE,
    priority          ENUM('Deferred', 'Standard', 'Urgent') NOT NULL,
    status            ENUM('PENDING_ON_PROVIDER', 'PENDING_ON_PAYER', 'COMPLETED', 'QUEUED', 'ERROR') NOT NULL,
    ai_summary        TEXT,
    patient_id      VARCHAR(255)  NOT NULL,
    practitioner_id VARCHAR(255),
    provider_name     VARCHAR(255),
    date_submitted    DATETIME      DEFAULT CURRENT_TIMESTAMP,
    is_appeal BOOLEAN DEFAULT False,
    PRIMARY KEY (request_id)
);
