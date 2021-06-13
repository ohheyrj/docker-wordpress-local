#!/bin/bash

trap cleanup SIGKILL SIGTERM SIGHUP SIGINT EXIT

cleanup() {
    echo "[INFO] Stopping container"
    if [ "$SYNC_S3" -eq "1" ]; then
        TIMESTAMP=$(date "+%Y.%m.%d-%H.%M.%S")
        echo "[INFO] Sync files back to S3..."
        aws s3 sync  /www/ s3://$S3_BUCKET/
        echo "[INFO]...Done"
    else
        echo "[INFO] Syncing files disabled"
    fi
}

if [ -z $SYNC_S3 ]; then
    export SYNC_S3=0
fi

export PHP_FPM_USER="www"
export PHP_FPM_GROUP="www"
export PHP_FPM_LISTEN_MODE="0660"
export PHP_MEMORY_LIMIT="512M"
export PHP_MAX_UPLOAD="50M"
export PHP_MAX_FILE_UPLOAD="200"
export PHP_MAX_POST="100M"
export PHP_DISPLAY_ERRORS="On"
export PHP_DISPLAY_STARTUP_ERRORS="On"
export PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR"
export PHP_CGI_FIX_PATHINFO=0

sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.d/www.conf
sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.d/www.conf
sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php7/php-fpm.d/www.conf
sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.d/www.conf
sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.d/www.conf
sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php7/php-fpm.d/www.conf #uncommenting line

sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php7/php.ini
sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php7/php.ini
sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php7/php.ini
sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini
sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php7/php.ini
sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini
sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini
sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php7/php.ini

chown -R www:www /www

if [ -n "$NGINX_PORT" ]; then
    echo "[INFO] Changing Port to $NGINX_PORT"
    sed  -ri "s/(\s*listen\s*)80;/\1$NGINX_PORT;/g" /etc/nginx/nginx.conf
fi

if [ "$SYNC_S3" -eq 1 ]; then
    if [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ]; then
        echo "[ERROR] No AWS Creds passed to container..."
        exit
    fi

    if [ -z $S3_BUCKET ]; then
        echo "[ERROR] No backup buckets specified...."
        exit
    fi

    echo "[INFO] Sync files from S3 bucket..."
    aws s3 sync s3://$S3_BUCKET /www/
else
    echo "[INFO] Not syncing S3 bucket contents"
fi

echo "[INFO] Correct ownership of files..."
chown -R www: /www

php-fpm7
nginx
echo "[INFO] Setup complete!"
while true
do
    tail -f /dev/null & wait ${!}
done