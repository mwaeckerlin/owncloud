#!/bin/bash -e

cd $INSTDIR
if ! test -f config/config.php; then # initial run
    # configure apache
    if test -z "$BASEPATH" -o "$BASEPATH" = "/"; then
        sed -i '/Alias \/owncloud /d' /etc/apache2/conf-available/owncloud.conf
        sed -i 's,DocumentRoot.*,DocumentRoot '$INSTDIR',' /etc/apache2/sites-available/000-default.conf
    else
        sed -i 's,Alias *[^ ]* ,Alias '"$BASEPATH"' ,' /etc/apache2/conf-available/owncloud.conf
    fi
    if ! grep -q "php_value max_input_time" $INSTDIR/.htaccess; then
        sed -i '/php_value upload_max_filesize.*$/a  php_value max_input_time ${MAX_INPUT_TIME}' \
            $INSTDIR/.htaccess
    fi
    if ! grep -q "php_value max_execution_time" $INSTDIR/.htaccess; then
        sed -i '/php_value upload_max_filesize.*$/a  php_value max_execution_time ${MAX_INPUT_TIME}' \
            $INSTDIR/.htaccess
    fi
    sed -i \
        -e 's,\(php_value *upload_max_filesize *\).*,\1'${UPLOAD_MAX_FILESIZE}',' \
        -e 's,\(php_value *post_max_size *\).*,\1'${UPLOAD_MAX_FILESIZE}',' \
        -e 's,\(php_value max_input_time *\).*,\1'${MAX_INPUT_TIME}',' \
        -e 's,\(php_value max_execution_time *\).*,\1'${MAX_INPUT_TIME}',' \
        $INSTDIR/.htaccess
    
    # install owncloud
    USER=${ADMIN_USER:-admin}
    PASS=${ADMIN_PWD:-$(pwgen 20 1)}
    for ((i=10; i>0; --i)); do # database connection sometimes fails retry 10 times
        if sudo -u www-data ./occ maintenance:install \
            --database $(test -n "$MYSQL_ENV_MYSQL_PASSWORD" && echo mysql || echo sqlite) \
            --database-name "${MYSQL_ENV_MYSQL_DATABASE}" \
            --database-host "mysql" \
            --database-user "$MYSQL_ENV_MYSQL_USER" \
            --database-pass "$MYSQL_ENV_MYSQL_PASSWORD" \
            --admin-user "${USER}" \
            --admin-pass "${PASS}" \
            --data-dir "${DATADIR}" \
            --no-interaction; then
            break
        fi
        echo "#### ERROR in installation; retry: $i" 1>&2
        if test -f config/config.php; then
            rm config/config.php
        fi
        sleep 5
    done
    if ! test -f config/config.php; then
        echo "#### ERROR in installation, please analyse" 1>&2
        sleep infinity
    fi
    if test "$PASS" != "$ADMIN_PWD"; then
        echo "************************************"
        echo "admin-user:     $USER"
        echo "admin-password: $PASS"
        echo "************************************"
    fi
else
    if ! sudo -u www-data ./occ upgrade --no-interaction; then
        echo "#### ERROR in upgrade, please analyse" 1>&2        
    fi
fi

sudo -u www-data ./occ log:owncloud --file=/var/log/owncloud.log --enable
if test -n "$WEBROOT"; then
    sudo -u www-data ./occ config:system:set overwritewebroot --value "${WEBROOT}"
fi
if test -n "$URL"; then
    sudo -u www-data ./occ config:system:set overwritehost --value "${URL}"
    sudo -u www-data ./occ config:system:set trusted_domains 1 --value "${URL}"
fi
apache2ctl -DFOREGROUND
