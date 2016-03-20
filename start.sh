#!/bin/bash -e

if test -z "$BASEPATH" -o "$BASEPATH" = "/"; then
    sed -i '/Alias \/owncloud /d' /etc/apache2/conf-available/owncloud.conf
    sed -i 's,DocumentRoot.*,DocumentRoot /var/www/owncloud,' /etc/apache2/sites-available/000-default.conf
else
    sed -i 's,Alias *[^ ]* ,Alias '"$BASEPATH"' ' /etc/apache2/conf-available/owncloud.conf
fi

if ! grep -q php_value max_input_time /var/www/owncloud/.htaccess; then
    sed -i '/php_value upload_max_filesize.*$/a  php_value max_input_time ${MAX_INPUT_TIME}' \
        /var/www/owncloud/.htaccess
fi
if ! grep -q php_value max_execution_time /var/www/owncloud/.htaccess; then
    sed -i '/php_value upload_max_filesize.*$/a  php_value max_execution_time ${MAX_INPUT_TIME}' \
        /var/www/owncloud/.htaccess
fi

sed -i \
    -e 's,\(php_value *upload_max_filesize *\).*,\1'${UPLOAD_MAX_FILESIZE}',' \
    -e 's,\(php_value *post_max_size *\).*,\1'${UPLOAD_MAX_FILESIZE}',' \
    -e 's,\(php_value max_input_time *\).*,\1'${MAX_INPUT_TIME}',' \
    -e 's,\(php_value max_execution_time *\).*,\1'${MAX_INPUT_TIME}',' \
    /var/www/owncloud/.htaccess

apache2ctl -DFOREGROUND
