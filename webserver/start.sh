#!/bin/bash

# Initialize database
/usr/local/bin/init-db.sh

# Start Apache in foreground
echo "Starting Apache web server..."
apachectl -D FOREGROUND
