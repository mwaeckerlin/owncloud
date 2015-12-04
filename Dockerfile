# docker rm -f owncloud-mysql
# docker run -d --name owncloud-mysql -e MYSQL_ROOT_PASSWORD=123456 -e MYSQL_DATABASE=owncloud -e MYSQL_USER=owncloud -e MYSQL_PASSWORD=123456 mysql
# docker run --rm --name owncloud -it -p 80:80 --link owncloud-mysql:mysql ubuntu bash
FROM ubuntu
MAINTAINER mwaeckerlin
ENV TERM="xterm"

EXPOSE 80
ENV UPLOAD_MAX_FILESIZE "8G"
ENV MAX_INPUT_TIME "3600"

ENV SOURCE "download.owncloud.org/download/repositories/stable/Ubuntu_"
RUN apt-get install -y wget
RUN wget -nv https://${SOURCE}$(lsb_release -rs)/Release.key -O- | apt-key add -
RUN echo "deb http://${SOURCE}$(lsb_release -rs)/ /" > /etc/apt/sources.list.d/oc.list
RUN apt-get update
RUN apt-get install -y --no-install-recommends owncloud owncloud-config-apache libreoffice-writer apache2 php5 php5-gd php5-curl php5-json php5-common php5-intl php-pear php-apc php-xml-parser libapache2-mod-php5 php5-mysql mysql-client
RUN sed -i '/Alias \/owncloud /d' /etc/apache2/conf-available/owncloud.conf
RUN sed -i 's,DocumentRoot.*,DocumentRoot /var/www/owncloud,' /etc/apache2/sites-available/000-default.conf
RUN sed -i \
        -e '/php_value upload_max_filesize.*$/a  php_value max_input_time ${MAX_INPUT_TIME}' \
        -e '/php_value upload_max_filesize.*$/a  php_value max_execution_time ${MAX_INPUT_TIME}' \
        /var/www/owncloud/.htaccess

VOLUME /var/www/owncloud
CMD sed -i \
        -e 's,\(php_value *upload_max_filesize *\).*,\1'${UPLOAD_MAX_FILESIZE}',' \
        -e 's,\(php_value *post_max_size *\).*,\1'${UPLOAD_MAX_FILESIZE}',' \
        /var/www/owncloud/.htaccess && \
    apache2ctl -DFOREGROUND
