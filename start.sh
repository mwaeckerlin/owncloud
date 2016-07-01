#!/bin/bash -e

cd $INSTDIR

# download missing apps
if test -n "$APPS"; then
    for a in $APPS; do
        if ! test -d apps/$a; then
            cd apps
            link=$(wget -O- -q https://github.com/owncloud/$a/releases \
                   | sed -n 's,.*href="\(/[^"]*/'"$a"'/[^"]*\.tar\.gz\)".*,\1,p' \
                   | sort -h | egrep -v 'beta|alpha|RC' | tail -1)
            echo "download: $a from $link"
            sudo -u www-data mkdir $a
            wget -O- -q https://github.com$link \
                | sudo -u www-data tar xz -C $a --strip-components 1
            cd ..
        fi
    done
fi

# configure php5 and apache
if test -z "$BASEPATH" -o "$BASEPATH" = "/"; then
    sed -i '/Alias \/owncloud /d' /etc/apache2/conf-available/owncloud.conf
    sed -i 's,DocumentRoot.*,DocumentRoot '$INSTDIR',' /etc/apache2/sites-available/000-default.conf
else
    grep -q Alias /etc/apache2/conf-available/owncloud.conf && \
        sed -i 's,Alias *[^ ]* ,Alias '"$BASEPATH"' ,' /etc/apache2/conf-available/owncloud.conf || \
        sed -i '0aAlias '"$BASEPATH" /etc/apache2/conf-available/owncloud.conf
fi
cat > /etc/php5/apache2/conf.d/99-owncloud.ini <<EOF
max_input_time = ${MAX_INPUT_TIME}
max_execution_time = ${MAX_INPUT_TIME}
upload_max_filesize = ${UPLOAD_MAX_FILESIZE}
post_max_size = ${UPLOAD_MAX_FILESIZE}
max_input_time = ${MAX_INPUT_TIME}
max_execution_time = ${MAX_INPUT_TIME}
EOF

# configure or update owncloud
if ! test -f config/config.php; then # initial run
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
else # upgrade owncloud
    if ! sudo -u www-data ./occ upgrade --no-interaction && test $? -ne 3; then
        if ! sudo -u www-data ./occ maintenance:repair --no-interaction ||
            ( ! sudo -u www-data ./occ upgrade --no-interaction && test $? -ne 3 ); then
            echo "#### ERROR in upgrade, please analyse" 1>&2
        fi
    fi
fi

cat > /etc/cron.d/owncloud <<EOF
*/15  *  *  *  * www-data php -f $INSTDIR/cron.php
EOF
chmod +x /etc/cron.d/owncloud
sudo -u www-data ./occ log:owncloud --file=/var/log/owncloud.log --enable
if test -n "$WEBROOT"; then
    sudo -u www-data ./occ config:system:set overwritewebroot --value "${WEBROOT}"
fi
if test -n "$URL"; then
    sudo -u www-data ./occ config:system:set overwritehost --value "${URL}"
    sudo -u www-data ./occ config:system:set trusted_domains 1 --value "${URL}"
fi
if test -n "$APPS"; then
    for a in $APPS; do
        sudo -u www-data ./occ app:enable $a
    done
fi
if test -f /run/apache2/apache2.pid; then
    rm /run/apache2/apache2.pid;
fi;
apache2ctl -DFOREGROUND
