# docker rm -f owncloud-mysql
# docker run -d --name owncloud-mysql -e MYSQL_ROOT_PASSWORD=1233456 -e MYSQL_DATABASE=owncloud -e MYSQL_USER=owncloud -e MYSQL_PASSWORD=123456 mysql
# docker run --rm --name owncloud -it -p 80:80 --link owncloud-mysql:mysql ubuntu bash
FROM ubuntu
MAINTAINER mwaeckerlin
software-properties-common
ENV SOURCE "download.owncloud.org/download/repositories/stable/Ubuntu_"
RUN apt-get install -y wget
RUN wget -nv https://${SOURCE}$(lsb_release -rs)/Release.key -O- | apt-key add -
RUN echo "deb http://${SOURCE}$(lsb_release -rs)/ /" > /etc/apt/sources.list.d/oc.list
RUN apt-get update
RUN apt-get install -y --no-install-recommends owncloud owncloud-config-apache libreoffice-writer apache2 php5 php5-gd php5-curl php5-json php5-common php5-intl php-pear php-apc php-xml-parser libapache2-mod-php5 php5-mysqlnd mysql-client
RUN sed -i '/Alias \/owncloud /d' /etc/apache2/conf-available/owncloud.conf
RUN sed -i 's,DocumentRoot.*,DocumentRoot /var/www/owncloud,' /etc/apache2/sites-available/000-default.conf

VOLUME /var/www/owncloud
CMD apache2ctl -DFOREGROUND
