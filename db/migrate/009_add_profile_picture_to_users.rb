require_relative '../../app/helpers/database'

conn = Database.connection

conn.exec <<~SQL
  ALTER TABLE users
  ADD COLUMN profile_picture_id INTEGER,
  ADD CONSTRAINT fk_profile_picture
    FOREIGN KEY (profile_picture_id)
    REFERENCES pictures(id)
    ON DELETE SET NULL;
SQL

conn.close
