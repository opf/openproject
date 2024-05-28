#!/bin/bash

set -eox pipefail

JOBS=$(nproc)
echo 'drop database if exists appdb ; create database appdb' | psql -v ON_ERROR_STOP=1 -d postgres
cat db/structure.sql | psql -v ON_ERROR_STOP=1 -d appdb
# create and load schema for test databases "appdb1" to "appdb$JOBS", far faster than using parallel_rspec tasks for that
for i in $(seq 1 $JOBS); do
  echo "drop database if exists appdb$i ; create database appdb$i with template appdb owner $PGUSER;" | psql -v ON_ERROR_STOP=1 -d postgres
done