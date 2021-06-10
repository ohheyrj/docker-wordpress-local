FROM ubuntu:latest

RUN apt-get -y update

RUN apt-get -y dist-upgrade

RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

RUN apt-get install -y apache2

RUN apt-get install -y php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip libapache2-mod-php  php-mysql

RUN apt-get install -y mysql-server

RUN apt-get install -y curl unzip expect

COPY wordpress.conf /etc/apache2/sites-available/wordpress.conf

RUN ln -s /etc/apache2/sites-available/wordpress.conf /etc/apache2/sites-enabled/wordpress.conf

RUN a2enmod rewrite

RUN apache2ctl configtest

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

COPY mysql_secure_installation_auto.sh /data/mysql_secure_installation_auto.sh

RUN rm /var/www/html/*

COPY entry.sh /data/entry.sh

RUN chmod +x /data/*.sh

ENTRYPOINT [ "/data/entry.sh" ]

EXPOSE 80