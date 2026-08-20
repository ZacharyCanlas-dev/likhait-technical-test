-- Provisioning only. This runs from docker-entrypoint-initdb.d before Rails
-- starts, and both migrations use `if_not_exists: true` -- a table created
-- here would silently suppress them while still recording in schema_migrations.

CREATE DATABASE IF NOT EXISTS expense_system_development
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

CREATE DATABASE IF NOT EXISTS expense_system_test
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

GRANT ALL PRIVILEGES ON expense_system_development.* TO 'expense_user'@'%';
GRANT ALL PRIVILEGES ON expense_system_test.* TO 'expense_user'@'%';
FLUSH PRIVILEGES;
