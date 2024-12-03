#!/usr/bin/env bash

echo "Modify config here"
sed -e '$i\' -e 'host all all 172.20.0.0/16 md5\' /var/lib/postgresql/data/pg_hba.conf > /tmp/temp.txt
mv /tmp/temp.txt /var/lib/postgresql/data/pg_hba.conf
cat /var/lib/postgresql/data/pg_hba.conf