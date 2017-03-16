# Example use with volumes and MySQL database behind a reverse proxy:
# docker run -d --name owncloud-mysql-volume mysql sleep infinity
# docker run -d --name owncloud-volume mwaeckerlin/owncloud sleep infinity
# docker run -d --name owncloud-mysql -e MYSQL_ROOT_PASSWORD=$(pwgen 20 1) -e MYSQL_DATABASE=owncloud -e MYSQL_USER=owncloud -e MYSQL_PASSWORD=$(pwgen 20 1) --volumes-from owncloud-mysql-volume mysql
# docker run -d --name owncloud -e URL="example.com" -e UPLOAD_MAX_FILESIZE=16G -e MAX_INPUT_TIME=7200 -e BASEPATH=/owncloud --volumes-from owncloud-volume --link owncloud-mysql:mysql mwaeckerlin/owncloud
# docker run -d -p 80:80 -p 443:443 [...] --link owncloud:dev.marc.waeckerlin.org%2fowncloud mwaeckerlin/reverse-proxy
FROM mwaeckerlin/ubuntu-base
MAINTAINER mwaeckerlin

EXPOSE 80
ENV UPLOAD_MAX_FILESIZE "8G"
ENV MAX_INPUT_TIME "3600"
ENV BASEPATH ""
ENV WEBROOT ""
ENV ADMIN_USER ""
ENV ADMIN_PWD ""
ENV URL ""

# default: your choice
#ENV APPS ""

# recommended apps: disable activity and gallery (replace with galleryplus)
#ENV APPS "-activity -gallery calendar contacts galleryplus:@interfasys notes user_ldap"

# more examples for APPS
#ENV APPS "calendar contacts documents music news notes ownnote"
#ENV APPS "announcementcenter calendar contacts documents encryption external files_antivirus files_external files_w2g mail music news notes ojsxc ownbackup ownnote shorten user_external"
#ENV APPS "announcementcenter calendar contacts documents files_w2g music news notes ojsxc ownbackup ownnote"

# compile time variables
ENV INSTDIR "/var/www/owncloud"
ENV DATADIR "/var/www/owncloud/data"
ENV CONFDIR "/var/www/owncloud/config"
ENV APPSDIR "/var/www/owncloud/apps"
ENV SOURCE "download.owncloud.org/download/repositories/stable/Ubuntu_"
RUN wget -nv https://${SOURCE}$(lsb_release -rs)/Release.key -O- | apt-key add -
RUN echo "deb http://${SOURCE}$(lsb_release -rs)/ /" > /etc/apt/sources.list.d/oc.list
RUN apt-get update && apt-get install -y owncloud php-ldap exim4 mysql-client pwgen sudo unzip
RUN test -f /etc/apache2/conf-available/owncloud.conf || apt-get install -y --no-install-recommends owncloud-config-apache

VOLUME $DATADIR
VOLUME $CONFDIR
VOLUME $APPSDIR
WORKDIR $INSTDIR
ADD start.sh /start.sh
CMD /start.sh
