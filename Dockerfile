FROM ubuntu:latest

RUN apt-get -y update

RUN apt-get -y dist-upgrade

RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

RUN apt-get install -y php php-mysql

RUN apt-get install -y mysql-server

RUN apt-get install -y nginx

COPY mysql_secure_installation_auto.sh /data/mysql_secure_installation_auto.sh

COPY entry.sh /data/entry.sh

RUN chmod +x /data/*.sh

ENTRYPOINT [ "/data/entry.sh" ]

EXPOSE 80