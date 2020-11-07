ARG IMAGE=php:7.3-fpm
FROM $IMAGE
LABEL MAINTAINER "David Snider <david@davidsnider.org>"

ADD icingaweb2 /usr/share/icingaweb2

RUN apt-get update && \
    apt-get -y install libpng-dev libpq-dev && \
    docker-php-source extract && \
    docker-php-ext-install gd gettext pdo pgsql pdo_pgsql && \
    docker-php-source delete

ADD webconfig /etc/icingaweb2
RUN mkdir /etc/icingaweb2/enabledModules
RUN chmod -R ug+rw /etc/icingaweb2
RUN ln -s /usr/share/icingaweb2/modules/monitoring /etc/icingaweb2/enabledModules/monitoring
