FROM ubuntu
MAINTAINER mwaeckerlin

ENV SOURCE "download.owncloud.org/download/repositories/stable/xUbuntu_"
RUN apt-get install -y wget
RUN wget -nv https://${SOURCE}$(lsb_release -rs)/Release.key -O- | apt-key add -
RUN echo "deb http://${SOURCE}$(lsb_release -rs)/ /" > /etc/apt/sources.list.d/oc.list
RUN apt-get update
RUN apt-get install -y --no-install-recommends owncloud libreoffice-writer

VOLUME /var/www/owncloud
CMD apache2ctl -DFOREGROUND
