ARG IMAGE=nginx:latest
FROM $IMAGE
MAINTAINER David Snider <david@davidsnider.org>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends php7.3 php7.3-intl php7.3-imagick php7.3-gettext php7.3-gd php7.3-curl php7.3-mbstring
ADD icingaweb2 /usr/share/icingaweb2
RUN addgroup --system icingaweb2
RUN adduser nginx icingaweb2

ADD webconfig /etc/icingaweb2
RUN mkdir /etc/icingaweb2/enabledModules
RUN chown -R nginx:icingaweb2 /etc/icingaweb2
RUN chmod -R ug+rw /etc/icingaweb2
RUN ln -s /usr/share/icingaweb2/modules/monitoring /etc/icingaweb2/enabledModules/monitoring
