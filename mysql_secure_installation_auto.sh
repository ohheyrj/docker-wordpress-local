#!/bin/bash

MYSQL_ROOT_PASSWORD=`date +%s | sha256sum | base64 | head -c 32`

echo "[IMPORTANT] THIS IS YOUR MYSQL ROOT PASSWORD, THIS SHOULD BE CHANGED: $MYSQL_ROOT_PASSWORD"

SECURE_MYSQL=$(expect -c "

set timeout 10
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none):\"
send \"$MYSQL\r\"

expect \"Change the root password?\"
send \"n\r\"

expect \"Remove anonymous users?\"
send \"y\r\"

expect \"Disallow root login remotely?\"
send \"y\r\"

expect \"Remove test database and access to it?\"
send \"y\r\"

expect \"Reload privilege tables now?\"
send \"y\r\"

expect eof
")

touch /data/.mysql.secure