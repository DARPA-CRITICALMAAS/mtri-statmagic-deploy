# mtri-statmagic-deploy
This repository contains resources to build and deploy several Docker containers needed for the MTRI Statmagic application
as well as the beak-ta3 server. The Docker containers are grouped together in profiles allowing the separate deployment
of containers across multiple hosts, if necessary. A description of the deployed containers can be seen below.
- `application` profile
  - `statmagic-web-app` container
    - Runs the Django web application containing the Statmagic website
  - `statmagic-database` container
    - Hosts the postgis database used by the statmagic application
- `tile` profile
  - `statmagic-cdr-sync` container
    - Executes a periodic syncing process to copy relevant CDR layers and re-generate the mapfile used by the tileserver
  - `statmagic-tileserver` container
    - Hosts the tileserver used by the statmagic application
- `beak` profile
  - `beak-som` container
    - Hosts the beak-ta3 server


## Clone our repositories
```bash
git clone https://github.com/DARPA-CRITICALMAAS/mtri-statmagic-deploy.git
```

```bash
cd mtri-statmagic-web
git submodule init
git submodule update
git pull origin main
```

## If you have not done so, set up AWS CLI
```bash
conda install awscliv2
awscliv2 configure
```

Set the default region name to `us-east-1`. 
## Obtain a copy of our database dump
```bash
awscliv2 s3 cp s3://statmagic/mtri/statmagic_2024-12-06.dump.out statmagic_dump.dump.out
```

Unzip to `statmagic_dump.dump.out`

## Obtain a copy of our mapfile:
```bash
awscliv2 s3 cp s3://statmagic/mtri/statmagic.map mtri-statmagic-deploy/statmagic.map
```

## Obtain a copy of our synchronized tile server files:
```bash
# TBD on where this will come from
```

## Set up environment variables.
Create a `.env` file with the following environment variables:
```bash
## Identity of the server running the postgis database.
# On a single host setup, this will be `postgis` if using Docker Compose or `statmagic-database` if using docker run
# On a multi host setup, this will be the ip address of the host running the `application` profile
DB_HOST=postgis

## Port that the database is exposed on. NOT CURRENTLY USED, 5432 IS DEFAULT
DB_PORT=5432

## Password set for postgis user. Needed by web-app to query postgis database
DJANGO_USER_STATMAGIC_PGPASS=gimme_gimme_gallium

## Location of the locally synced CDR layers used to generate the mapfile
TILESERVER_LOCAL_SYNC_FOLDER=/usr/local/project/datalayer_download/

## Identity of the server running the tileserver
# On a single host setup, this will be `tileserver` if using Docker Compose or `statmagic-tileserver` if using docker run
# On a multi host setup, this will be the ip address of the host running the `tile` profile
MAPSERVER_SERVER=tileserver

# CDR configuration
CDR_API_TOKEN=[CDR_API_TOKEN]
CDR_API=https://api.cdr.land
CDR_API_VERSION=v1
```
Create a `beak.env` file with the following environment variables:
```bash
# Identity of process interacting with CDR
SYSTEM_NAME=beak_via_mtri_$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13; echo)

# CDR configuration
CDR_API_TOKEN=[CDR_API_TOKEN]
CDR_HOST=https://api.cdr.land
CDR_API=$CDR_HOST
CDR_API=v1

# ngrok authentication token
NGROK_AUTHTOKEN=[NGROK_AUTHTOKEN]

# location of local datalayer cache.
DATALAYER_CACHE_DIR=/beak_datalayer_cache/
```
Any environment variable set to a string between square brackets, i.e. `[CDR_API_TOKEN]` must be replaced with your
own token.

## Build & launch containers:
To launch all containers on a single host, run:
```bash 
COMPOSE_PROFILES=* docker compose -f docker-compose.statmagic.yaml up --build
```

To launch a single profile, run the following command, where `PROFILE_NAME` is one of [`application`, `tile`, `beak`]
```bash
COMPOSE_PROFILES=PROFILE_NAME docker compose -f docker-compose.statmagic.yaml up --build
```

## View web app
Navigate to 
```
WEB_APP_HOST_IP:8000/statmagic
```

## Build & launch from images without compose

Either open 5 terminals (one for each container) or add the `-d` argument to the docker run command to detach (run in the background).
If you open new terminals, make sure to cd back to `mtri-statmagic-deploy` and source your `.env` file before each `docker run` command.
The web-app container should be started last.

If you are running all the containers on a single host, run the following:
```bash
# Source environment files
source .env
source beak.env

# Create volume for postgis data storage
docker volume create postgis_data

# Create network for containers
docker network create statmagic-network

# Launch beak-som container
docker run -d --env-file beak.env --name beak-som --restart always efvega/beak-som

# Launch postgis container
docker run -d --name statmagic-database --network statmagic-network -u postgres --restart always -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=statmagic -e DJANGO_USER_STATMAGIC_PGPASS=$DJANGO_USER_STATMAGIC_PGPASS -v postgis_data:/var/lib/postgresql/data -v ${PWD}/statmagic_dump.dump.out:/tmp/statmagic_dump.dump.out -v ${PWD}/init_scripts:/docker-entrypoint-initdb.d/ --health-cmd CMD-SHELL,pg_isready,-d,statmagic --health-interval 3s --health-retries 30 --health-timeout 3s postgis/postgis:14-3.5

# Launch cdr-sync container
#docker run --name cdr-sync --network statmagic-network --rm --entrypoint /bin/bash -v ./datalayer_download:${TILESERVER_LOCAL_SYNC_FOLDER} -v ./statmagic.map:/usr/local/project/statmagic.map --env-file .env efvega/mtri-statmagic-deploy-web-app -c "cron -f"
docker run -d --name statmagic-cdr-sync --network statmagic-network --entrypoint /bin/bash --restart always -v ./datalayer_download:${TILESERVER_LOCAL_SYNC_FOLDER} -v ./statmagic.map:/usr/local/project/statmagic.map --env-file .env efvega/statmagic-web-app -c "cron -f"

# Launch tileserver container
#docker run --name tileserver --network statmagic-network --rm -v ./datalayer_download:/usr/local/project/datalayer_download -v ./statmagic.map:/var/www/mapfiles/statmagic.map -v ./symbols.sym:/var/www/mapfiles/symbols.sym -v ./tileserver_000-default.conf:/etc/apache2/sites-available/000-default.conf -p 8081:80 efvega/mtri-statmagic-deploy-tileserver
docker run -d --name statmagic-tileserver --network statmagic-network --restart always -v ./datalayer_download:/usr/local/project/datalayer_download -v ./statmagic.map:/var/www/mapfiles/statmagic.map -v ./symbols.sym:/var/www/mapfiles/symbols.sym -v ./tileserver_000-default.conf:/etc/apache2/sites-available/000-default.conf -p 8081:80 efvega/statmagic-tileserver

# Launch web-app container 
#docker run --name web-app --network statmagic-network --rm -v ./statmagic_000-default.conf:/etc/apache2/sites-available/000-default.conf -v ./startup.sh:/usr/local/project/startup.sh -v ./datalayer_download:${TILESERVER_LOCAL_SYNC_FOLDER} -v ./statmagic.map:/usr/local/project/statmagic.map -p 8000:80 --env-file .env efvega/mtri-statmagic-deploy-web-app server
docker run -d --name statmagic-web-app --network statmagic-network --restart always -v ./statmagic_000-default.conf:/etc/apache2/sites-available/000-default.conf -v ./startup.sh:/usr/local/project/startup.sh -v ./datalayer_download:${TILESERVER_LOCAL_SYNC_FOLDER} -v ./statmagic.map:/usr/local/project/statmagic.map -p 8000:80 --env-file .env efvega/statmagic-web-app server
```
If you are running on multiple hosts, run the following instead:
```bash

```