require_relative '../../app/helpers/database'

conn = Database.connection

conn.exec <<~SQL
  CREATE TABLE IF NOT EXISTS tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
  );
SQL

conn.close
