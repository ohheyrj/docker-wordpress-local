#!/bin/bash

service mysql start
service nginx start

if [ ! -f /tmp/mysql_root_password.secret ]; then
    echo "Running MySQL setup..."
    sh /data/mysql_secure_installation_auto.sh
fi

tail -f /var/log/mysql/error.log
