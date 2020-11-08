#!/usr/bin/env bash
set -Eeuo

#What version of Icinga Web should we use?
ICINGA_VERSION=2.12.1
ICINGAWEB=2.8.2
ICINGA_SOURCE_URL=https://github.com/Icinga/icinga2/archive/v${ICINGA_VERSION}.tar.gz

# Get latest icingaweb
cd /tmp && rm -rf icingaweb2* v${ICINGAWEB}.zip  #the rm might fail, so we cd to tmp on the next line as well, gotta get the cd - populated again
cd - && cd /tmp && wget https://github.com/Icinga/icingaweb2/archive/v${ICINGAWEB}.zip && \
unzip v${ICINGAWEB}.zip && \
cd - && \
rm -rf icinga-web/icingaweb2 && \
rm -rf icinga-php7-fpm/icingaweb2 && \
cp -r /tmp/icingaweb2-${ICINGAWEB} icinga-web/icingaweb2
cp -r /tmp/icingaweb2-${ICINGAWEB} icinga-php7-fpm/icingaweb2
cp /tmp/icingaweb2-${ICINGAWEB}/etc/schema/pgsql.schema.sql ../bases/1-pgsql-web.sql

# Get latest icinga
cd /tmp && rm -rf icinga2* v${ICINGA_VERSION}.zip  #the rm might fail, so we cd to tmp on the next line as well, gotta get the cd - populated again
cd - && cd /tmp && wget ${ICINGA_SOURCE_URL} && \
tar -xvzf v${ICINGA_VERSION}.tar.gz && \
cd - && \
cp /tmp/icinga2-${ICINGA_VERSION}/lib/db_ido_pgsql/schema/pgsql.sql ../bases/postgres-ido.sql


TAG=$(date +"%Y%m%d%H%M")

#Remove all of the existing images
IMAGES=$(docker images|grep registry.thesniderpad.com/icinga- | awk '{print $3}')
if [ ! -z "$IMAGES" ]
then
 docker rmi --force $(docker images|grep registry.thesniderpad.com/icinga- | awk '{print $3}')
fi

# Create the individual images
docker build --pull --build-arg IMAGE=debian:buster -t registry.thesniderpad.com/icinga-server:${TAG} icinga-server
docker push registry.thesniderpad.com/icinga-server:${TAG}
docker tag registry.thesniderpad.com/icinga-server:${TAG} registry.thesniderpad.com/icinga-server:latest
docker push registry.thesniderpad.com/icinga-server:latest

# Create the individual images
docker build --pull --build-arg IMAGE=nginx:latest -t registry.thesniderpad.com/icinga-web:${TAG} icinga-web
docker push registry.thesniderpad.com/icinga-web:${TAG}
docker tag registry.thesniderpad.com/icinga-web:${TAG} registry.thesniderpad.com/icinga-web:latest
docker push registry.thesniderpad.com/icinga-web:latest

# Create the individual images
docker build --pull --build-arg IMAGE=php:7.3-fpm -t registry.thesniderpad.com/icinga-php7-fpm:${TAG} icinga-php7-fpm
docker push registry.thesniderpad.com/icinga-php7-fpm:${TAG}
docker tag registry.thesniderpad.com/icinga-php7-fpm:${TAG} registry.thesniderpad.com/icinga-php7-fpm:latest
docker push registry.thesniderpad.com/icinga-php7-fpm:latest
