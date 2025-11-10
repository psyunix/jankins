#!/bin/bash

# Start MariaDB
service mariadb start

# Wait for MariaDB to be ready
until mysqladmin ping -h localhost --silent; do
    echo 'Waiting for MariaDB to be available...'
    sleep 2
done

# Initialize database if not exists
mysql -e "CREATE DATABASE IF NOT EXISTS testdb;"
mysql -e "CREATE USER IF NOT EXISTS 'testuser'@'localhost' IDENTIFIED BY 'testpass123';"
mysql -e "GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Create test table and insert sample data
mysql testdb <<EOF
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO users (id, name, email) VALUES
    (1, 'John Doe', 'john@example.com'),
    (2, 'Jane Smith', 'jane@example.com'),
    (3, 'Bob Johnson', 'bob@example.com'),
    (4, 'Alice Williams', 'alice@example.com');
EOF

echo "Database initialized successfully!"
