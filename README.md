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

## If you have not done so, set up AWS CLI
```bash
conda install awscliv2
awscliv2 configure
```

Set the default region name to `us-east-1`. 
## Get a copy of our database dump
```bash
awscliv2 s3 cp s3://statmagic/mtri/statmagic_2024-11-25.dump.out.gz mtri-statmagic-deploy/statmagic_dump.dump.out.gz
```

Unzip to `statmagic_dump.dump.out`

# TODO: Switch from pip to conda
