#!/bin/bash
# Database initialization script for Cafe Grader
# This script runs automatically when MySQL container starts for the first time
# MySQL built-in user creation handles the main database, we just need to add the queue database

mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
-- Create the additional queue database
CREATE DATABASE IF NOT EXISTS grader_queue;

-- Grant privileges on queue database to the MySQL user (MySQL already created the user)
GRANT ALL PRIVILEGES ON grader_queue.* TO '${MYSQL_USER}'@'%';

-- Flush privileges
FLUSH PRIVILEGES;
EOF