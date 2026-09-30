CREATE TABLE IF NOT EXISTS servers (
    id SERIAL PRIMARY KEY,
    hostname VARCHAR(100) UNIQUE NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    os VARCHAR(100),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO servers
    (hostname, ip_address, os, status)
VALUES
    ('server01', '10.0.0.1', 'Rocky Linux 8', 'running'),
    ('server02', '10.0.0.2', 'Rocky Linux 8', 'running'),
    ('server03', '10.0.0.3', 'Rocky Linux 8', 'running'),
    ('server04', '10.0.0.4', 'Rocky Linux 8', 'running'),
    ('server05', '10.0.0.5', 'Rocky Linux 8', 'running'),
    ('server06', '10.0.0.6', 'Rocky Linux 8', 'running'),
    ('server07', '10.0.0.7', 'Rocky Linux 8', 'running'),
    ('server08', '10.0.0.8', 'Rocky Linux 8', 'stopped'),
    ('server09', '10.0.0.9', 'Rocky Linux 8', 'stopped'),
    ('server10', '10.0.0.10', 'Rocky Linux 8', 'stopped');