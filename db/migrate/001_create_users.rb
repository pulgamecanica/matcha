require_relative '../../app/helpers/database'

conn = Database.connection

conn.exec <<~SQL
  CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_digest VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('male', 'female', 'other')),
    sexual_preferences VARCHAR(20) NOT NULL CHECK (sexual_preferences IN ('male', 'female', 'non_binary', 'everyone')),
    biography TEXT,
    profile_picture_id INTEGER,
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_banned BOOLEAN DEFAULT FALSE,
    fame_rating FLOAT DEFAULT 0.0,
    latitude FLOAT,
    longitude FLOAT,
    online_status BOOLEAN DEFAULT FALSE,
    last_seen_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
SQL

conn.close
