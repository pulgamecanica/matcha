require_relative '../../app/helpers/database'

conn = Database.connection

conn.exec <<~SQL
  CREATE TABLE IF NOT EXISTS location_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    city VARCHAR(100),
    country VARCHAR(100),
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
SQL

conn.close