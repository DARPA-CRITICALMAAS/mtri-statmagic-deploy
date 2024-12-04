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

      # Check if required vars exist in /etc/apache2/envvars
      if ! grep -q "CDR_API_TOKEN" /etc/apache2/envvars; then
        echo "export CDR_API_TOKEN=$CDR_API_TOKEN" >> /etc/apache2/envvars
        echo "export DJANGO_USER_STATMAGIC_PGPASS=$DJANGO_USER_STATMAGIC_PGPASS" >> /etc/apache2/envvars
        echo "export SECRET_KEY=$SECRET_KEY" >> /etc/apache2/envvars
        echo "export CDR_SCHEMAS_DIRECTORY=/usr/local/project/cdr_schemas" >> /etc/apache2/envvars
      fi

      source $ENV_PATH/bin/activate
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