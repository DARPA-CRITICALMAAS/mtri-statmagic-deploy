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

#      # Check if requirements.txt exists, and there is no env already built
#      if [ -e $BASE_PATH/requirements.txt ] && [ ! -d $BASE_PATH/env ]; then
#          sudo pip3 install virtualenv
#          cd $BASE_PATH
#          mkdir /usr/local/pythonenv
#          virtualenv $ENV_PATH
#          source $ENV_PATH/bin/activate
#
#          # Install Python dependencies
#          pip install --upgrade pip wheel
#          pip install --no-cache-dir -r requirements.txt
#
#          # Install GDAL separate (because nothing with GDAL is easy...)
#          pip install GDAL==$(gdal-config --version | awk -F'[.]' '{print $1"."$2}')
#
#          # Clone and install DARPA cdr_schemas repository
#          git clone https://github.com/DARPA-CRITICALMAAS/cdr_schemas.git
#          cd cdr_schemas
#          pip install -e .
#      else
#          source $ENV_PATH/bin/activate
#      fi
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