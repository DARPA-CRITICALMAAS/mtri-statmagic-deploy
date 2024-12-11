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