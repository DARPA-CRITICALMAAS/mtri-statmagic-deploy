# mtri-statmagic-deploy

## Clone our repositories

```bash
git clone https://github.com/DARPA-CRITICALMAAS/mtri-statmagic-deploy.git
```

```bash
cd mtri-statmagic-web
git submodule init
git submodule update
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
Override the variables in `.env`. These include
```bash
# Identity of the server running the postgis database
DB_HOST=postgis

# Port that the database is exposed on. NOT CURRENTLY USED, 5432 IS DEFAULT
DB_PORT=5432

# Password set for postgis user. Needed by web-app to query postgis database
DJANGO_USER_STATMAGIC_PGPASS=gimme_gimme_gallium

# API Token to query CDR
CDR_API_TOKEN=

# Location of the locally synced CDR layers used to generate the mapfile
TILESERVER_LOCAL_SYNC_FOLDER=/usr/local/project/datalayer_download/

# Identity of the server running the tileserver
MAPSERVER_SERVER=tileserver

# CDR configuration
CDR_API=https://api.cdr.land
CDR_API_VERSION=v1
```

## Build & launch containers:
```bash 
docker compose -f docker-compose.statmagic.yaml up --build 
```

## View web app
Navigate to 
```
WEB_APP_HOST_IP:8000/statmagic
```

## Build & launch from images without compose
To load a container from an archive:
```bash
docker load -i image.tar
```

Either open 4 terminals (one for each container) or add the `-d` argument to the docker run command to detach (run in the background).
If you open new terminals, make sure to cd back to `mtri-statmagic-deploy` and source your `.env` file before each `docker run` command.
The web-app container should be started last.


```bash
# Create volume for postgis data storage
docker volume create postgis_data

# Create network for containers
docker network create statmagic-network

# Launch postgis container
docker run --name postgis --network statmagic-network --rm -u postgres -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=statmagic -e DJANGO_USER_STATMAGIC_PGPASS=$DJANGO_USER_STATMAGIC_PGPASS -v postgis_data:/var/lib/postgresql/data -v ${PWD}/statmagic_dump.dump.out:/tmp/statmagic_dump.dump.out -v ${PWD}/init_scripts:/docker-entrypoint-initdb.d/ --health-cmd CMD-SHELL,pg_isready,-d,statmagic --health-interval 3s --health-retries 30 --health-timeout 3s postgis/postgis:14-3.5

# Launch cdr-sync container
docker run --name cdr-sync --network statmagic-network --rm --entrypoint /bin/bash -v ./datalayer_download:${TILESERVER_LOCAL_SYNC_FOLDER} -v ./statmagic.map:/usr/local/project/statmagic.map --env-file .env efvega/mtri-statmagic-deploy-web-app -c "cron -f"

# Launch tileserver container
docker run --name tileserver --network statmagic-network --rm -v ./datalayer_download:/usr/local/project/datalayer_download -v ./statmagic.map:/var/www/mapfiles/statmagic.map -v ./symbols.sym:/var/www/mapfiles/symbols.sym -v ./tileserver_000-default.conf:/etc/apache2/sites-available/000-default.conf -p 8081:80 efvega/mtri-statmagic-deploy-tileserver

# Launch web-app container 
docker run --name web-abb --network statmagic-network --rm -v ./statmagic_000-default.conf:/etc/apache2/sites-available/000-default.conf -v ./startup.sh:/usr/local/project/startup.sh -v ./datalayer_download:${TILESERVER_LOCAL_SYNC_FOLDER} -v ./statmagic.map:/usr/local/project/statmagic.map -p 8000:80 --env-file .env efvega/mtri-statmagic-deploy-web-app server
```