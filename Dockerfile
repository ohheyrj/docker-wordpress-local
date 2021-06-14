FROM alpine:latest

VOLUME [ "/www" ]

RUN apk update; apk add nginx \
    php7-fpm \
    tzdata \
    php7-curl \
    php7-gd \
    php7-mbstring \
    php7-xml \
    php7-xmlrpc \
    php7-soap \
    php7-intl \
    php7-zip \
    php7-apache2 \
    php7-json \
    mysql-client \
    mysql \
    curl \
    unzip \
    expect \
    python3 \
    bash \
    php7-pdo_mysql \
    php7-mysqli \
    php7-simplexml \
    php7-xmlwriter \
    php7-session \
    php7-dom \
    py3-pip && rm -rf /var/cache/apk/*

RUN pip3 install --upgrade pip && pip3 install awscli && aws --version

RUN adduser -D -g 'www' www

RUN chown -R www:www /var/lib/nginx

COPY nginx.conf /etc/nginx/nginx.conf

COPY entrypoint.sh /data/entrypoint.sh

RUN chmod +x /data/entrypoint.sh

ENTRYPOINT [ "/data/entrypoint.sh" ]
