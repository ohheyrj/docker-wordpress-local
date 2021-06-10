#!/bin/bash

sync_s3() {
    echo "[INFO] Sync files back to S3..."
    aws s3 sync  /var/www/html/ s3://blog-systemsmystery-tech-wp-content-bucket/
    echo "[INFO]...Done"
}
echo "[INFO] Starting MySQL..."
service mysql start

echo "[INFO] Checking if MySQL has already been setup..."
if [ ! -f /data/.mysql.secure ]; then
    echo "[INFO] Running MySQL setup..."
    sh /data/mysql_secure_installation_auto.sh
else
    echo "[SKIP] MySQL already setup"
fi

# Check if the DB name has been provided
if [ -z $WP_DB_NAME ]; then
    echo "[INFO] Using wordpress database name wordpress"
    export WP_DB_NAME=wordpress
else
    echo "[INFO] Using provided wordpress database name $WP_DB_NAME"
fi

# Check if DB already exists.
if [ ! -d /var/lib/mysql/$WP_DB_NAME ]; then
    echo "[INFO] Creating database $WP_DB_NAME"
    echo "CREATE DATABASE $WP_DB_NAME;" | mysql
else
    echo "[SKIP] Database already exists"
fi

# Check if the DB username has been provided
if [ -z $WP_DB_USER ]; then
    echo "[INFO] Using wordpress database username wordpress"
    export WP_DB_USER=wordpress

else
    echo "[INFO] Using provided wordpress database username $WP_DB_USER"
fi

if [ -f /data/.mysql.db.pass ]; then
    echo "[SKIP] Found db password file"
else
    # Check if the DB password has been provided
    if [ -z $WP_DB_PASS ]; then
        echo "[INFO] Using wordpress database password wordpress"
        export WP_DB_PASS=`date +%s | sha256sum | base64 | head -c 32`
        echo $WP_DB_PASS > /data/.mysql.db.pass
        echo "[IMPORTANT] Password written to file /data/.mysql.db.pass"
        echo "[IMPORTANT] Save password securly, delete file and create a new empty file with the same name."
    else
        echo "[INFO] Using provided wordpress database password"
        export WP_DB_PASS=`cat /data/.mysql.db.pass`
        touch /data/.mysql.db.pass
    fi
fi

# Check if user already exists.
RESULT_VARIABLE="$(mysql -se "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$WP_DB_USER')")"
if [ $RESULT_VARIABLE = 1 ]; then
    echo "[SKIP] User already exists."
else
    echo "[INFO] Creating user $WP_DB_USER"
    echo "CREATE USER $WP_DB_USER IDENTIFIED BY '$WP_DB_PASS';" | mysql
    echo "GRANT ALL PRIVILEGES ON $WP_DB_NAME . * TO $WP_DB_USER;" | mysql
fi

if [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ]; then
    echo "[ERROR] No AWS Creds passed to container..."
    exit 1
fi

echo "[INFO] Sync files from S3 bucket..."
aws s3 sync s3://blog-systemsmystery-tech-wp-content-bucket /var/www/html/

echo "[INFO] Correct ownership of files..."
chown -R www-data: /var/www/html
echo "[INFO] Start Apache2"
service apache2 start

echo "[INFO] Setup complete!"
trap 'sync_s3' SIGTERM

while true
do
    wait ${!}
done
