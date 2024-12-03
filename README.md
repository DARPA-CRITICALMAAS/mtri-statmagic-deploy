# mtri-statmagic-deploy

## Clone our repositories

```bash
git clone https://github.com/DARPA-CRITICALMAAS/mtri-statmagic-deploy.git
```

```bash
cd mtri-statmagic-web
git submodule init
git submodule fetch
```

# TODO Figure out credentials for AWS 
## Get a copy of our database dump
Download from the shared MTRI bucket link [here](https://statmagic.s3.us-east-1.amazonaws.com/mtri/statmagic_2024-11-25.dump.out.gz) into `mtri-statmagic-deploy` directory.

# TODO: Environment variable for specifying name of database file
## Unzip to `statmagic_dump.dump.out`

# TODO: Switch from pip to conda
