#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Run a case command
case $1 in
    server)
      # Pull in Docker env
      WEBSITE_BASE_NAME="$(printenv WEBSITE_NAME)"
      BASE_PATH=/usr/local/project/${WEBSITE_BASE_NAME}
      ENV_PATH=/usr/local/pythonenv/${WEBSITE_BASE_NAME}-env

      source $ENV_PATH/bin/activate
      #. /opt/miniforge3/bin/activate statmagic-env

      # Generate secret key for django application
      secret_key=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

      # Check if required vars exist in /etc/apache2/envvars
      if ! grep -q "CDR_API_TOKEN" /etc/apache2/envvars; then
        echo "export CDR_API_TOKEN=$CDR_API_TOKEN" >> /etc/apache2/envvars
        echo "export DJANGO_USER_STATMAGIC_PGPASS=$DJANGO_USER_STATMAGIC_PGPASS" >> /etc/apache2/envvars
        echo "export SECRET_KEY='''$secret_key'''" >> /etc/apache2/envvars
        echo "export CDR_SCHEMAS_DIRECTORY=/usr/local/project/cdr_schemas" >> /etc/apache2/envvars
        echo "export DB_HOST=$DB_HOST" >> /etc/apache2/envvars
        echo "export DB_PORT=$DB_PORT" >> /etc/apache2/envvars
        echo "export MAPSERVER_SERVER=$MAPSERVER_SERVER" >> /etc/apache2/envvars
        echo "export TILESERVER_LOCAL_SYNC_FOLDER=$TILESERVER_LOCAL_SYNC_FOLDER" >> /etc/apache2/envvars
      fi

      # Change to $BASE_PATH
      cd $BASE_PATH
      # Make django migrations
      python manage.py makemigrations
      python manage.py migrate
      echo "Made Migrations..."
      # Add collect static
      python manage.py collectstatic --noinput
      # Startup apache2 server
      sudo apache2ctl -D FOREGROUND
    ;;

esac