ALTER TABLE users
    ADD COLUMN login_id VARCHAR(80) NULL AFTER name,
    ADD COLUMN password_hash VARCHAR(255) NULL AFTER email;

CREATE UNIQUE INDEX uk_users_login_id ON users (login_id);
