#!/usr/bin/env bash

cd /tmp
touch asdf
ls -lhtr
# chown postgres statmagic_dump.dump.out
# gunzip statmagic_dump.dump.out
psql -U postgres statmagic < statmagic_dump.dump.out