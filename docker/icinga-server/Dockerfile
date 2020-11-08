ARG TARGETPLATFORM
ARG BUILDPLATFORM
FROM debian:buster
LABEL maintainer="David Snider <david@davidsnider.org>"

RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM"
ENV ICINGA_VER=2.11.4-1.buster

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends wget gnupg gpg-agent software-properties-common \
 && wget -O - https://packages.icinga.com/icinga.key --no-check-certificate | apt-key add - \
 && add-apt-repository "deb http://packages.icinga.com/raspbian icinga-buster main" \
 && apt-get update \
 && apt-get -y dist-upgrade \
 && apt-get install -y --no-install-recommends icinga2=${ICINGA_VER} monitoring-plugins monitoring-plugins-basic \
                       monitoring-plugins-standard nagios-plugins-contrib netbase \
                       monitoring-plugins-common icinga2-ido-pgsql=${ICINGA_VER} \
                       curl nagios-nrpe-plugin html2text nagios-snmp-plugins libtimedate-perl \
                       python3-requests jq icinga2-bin=${ICINGA_VER} icinga2-common=${ICINGA_VER}

# Get Kubectl for kubernetes checks
RUN cd /tmp && \
    curl -LO --insecure https://storage.googleapis.com/kubernetes-release/release/`curl --insecure -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/`dpkg --print-architecture |tr -d "hf"`/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/bin/kubectl

RUN mkdir /run/icinga2
RUN chown -R nagios:nagios /run/icinga2

ADD scripts /etc/icinga2/scripts
ADD launch.sh /
RUN chmod +x /launch.sh

EXPOSE 5665

CMD ["/launch.sh"]
