#!/bin/bash

# This script is used to migrate an OpenProject (<= 8) database in MySQL to the latest version in Postgres.
# All that's needed is docker. The result will be a SQL dump to the current directory.
#
# We do the MySQL-to-Postgres migration because in the old OpenProject packages MySQL
# used to be the standard database. If you are already running on Postgres this script won't work as it is.
# For it to work it you will have to use postgres in every step and remove the line
# containing MYSQL_DATABASE_URL.

if [[ -z "$1" ]] || [[ -z "$2" ]]; then
  echo
  echo "  usage: bash migrate-from-pre-8.sh <docker host IP> <MySQL dump> [dump format = sql|custom (default)]"
  echo
  echo "  example: bash migrate-from-pre-8.sh 192.168.1.42 /var/db/openproject/backups/dump.sql"
  echo
  exit 1
fi

CURRENT_OP_MAJOR_VERSION="14"

SECONDS=0

DOCKER_HOST_IP=$1
MYSQL_DUMP_FILE=$2
DUMP_FORMAT=${3:-custom}

MYSQL_CONTAINER=opmysql
POSTGRES_CONTAINER=oppostgres
POSTGRES_VERSION=13
OP7_CONTAINER=op7
OP8_CONTAINER=op8
OP10_CONTAINER=op10
MIGRATE_CONTAINER=migrate8to10

REMOVE_CONTAINERS=true

POSTGRES_PORT=5439
MYSQL_PORT=3305 # has to be free on localhost
MYSQL_USER=root
MYSQL_PWD=root
DATABASE=openproject

SKIP_STEP_1=${SKIP_STEP_1:-false}
MIGRATION_TIMEOUT_S=600 # wait at most 10 minutes for the migration from 8 to 10 to finish

docker stop $MYSQL_CONTAINER || true
docker stop $POSTGRES_CONTAINER || true
docker stop $MIGRATE_CONTAINER || true

if [[ ! "$SKIP_STEP_1" = "true" ]]; then
  # STEP 1: Migrate from current (7) to 8 still in a MySQL database
  echo
  echo "1) Migrate to 8 in MySQL"

  echo
  echo "1.1) Starting mysql database..."
  if [[ ! `docker ps | grep $MYSQL_CONTAINER` ]]; then
    docker run --rm -p $MYSQL_PORT:3306 -d --name $MYSQL_CONTAINER -e MYSQL_ROOT_PASSWORD=$MYSQL_PWD mysql:5.6
    if [[ $? -gt 0 ]]; then exit 1; fi
    sleep 10
    echo "  database started"
  else
    echo "  already running"
  fi

  echo
  echo "1.2) Starting OpenProject 7"
  if [[ ! `docker ps | grep $OP7_CONTAINER` ]]; then
    docker run --rm -d --name $OP7_CONTAINER openproject/openproject:7 bash -c 'sleep 7200'
    if [[ $? -gt 0 ]]; then exit 1; fi
    echo "  OpenProject started"
  else
    echo "  OpenProject already running"
  fi

  echo
  echo "1.3) Starting OpenProject 8"
  if [[ ! `docker ps | grep $OP8_CONTAINER` ]]; then
    docker run --rm -d --name $OP8_CONTAINER openproject/openproject:8-mysql # can use `run -it` directly because the image doesn't support it yet in version 8
    if [[ $? -gt 0 ]]; then exit 1; fi
    echo "  OpenProject started"
  else
    echo "  OpenProject already running"
  fi

  echo
  echo "1.4) Creating MySQL database for migration from OP 7 to 8"
  echo "drop database if exists $DATABASE; create database $DATABASE;" | docker exec -i $MYSQL_CONTAINER mysql -p$MYSQL_PWD

  if [[ $? -gt 0 ]]; then
    echo "  Could not create database"
    exit 1
  else
    echo "  Created database"
  fi

  echo
  echo "1.5) Importing MySQL dump ($MYSQL_DUMP_FILE)"

  cat $MYSQL_DUMP_FILE | docker exec -i $MYSQL_CONTAINER mysql -p$MYSQL_PWD $DATABASE

  if [[ $? -gt 0 ]]; then
    echo "  Could not import database"
    exit 1
  else
    echo "  Imported database"
  fi

  echo
  echo "1.6) Migrating database from 6 to 7 ... (NOOP if already on 7)"

  docker exec -it $OP7_CONTAINER /bin/sh -c "DATABASE_URL=mysql2://$MYSQL_USER:$MYSQL_PWD@$DOCKER_HOST_IP:$MYSQL_PORT/$DATABASE bundle exec rake db:migrate"

  if [[ $? -gt 0 ]]; then
    echo "  Could not migrate database"
    exit 1
  else
    echo "  Migrated database"
  fi

  # Sometimes very old databases may not have all schema migrations recorded
  # even though the respective migrations were executed. If this is the case
  # you can uncomment this step and adjust it to insert the missing versions.
  #
  # echo
  # echo "1.6.1) Fixing schema migrations"
  #
  # echo '
  # INSERT INTO schema_migrations (version) VALUES
  #   (20110224000000), (20110226120112)
  # ;
  # ' | mysql -uroot -h 127.0.0.1 -P $MYSQL_PORT $DATABASE
  #
  # if [[ $? -gt 0 ]]; then
  #   echo "  Could not fix schema migrations"
  #   exit 1
  # else
  #   echo "  Fixed schema migrations"
  # fi

  echo
  echo "1.7) Migrating database from 7 to 8 ... (NOOP if already on 8)"

  docker exec -it $OP8_CONTAINER /bin/sh -c "DATABASE_URL=mysql2://$MYSQL_USER:$MYSQL_PWD@$DOCKER_HOST_IP:$MYSQL_PORT/$DATABASE bundle exec rake db:migrate"

  if [[ $? -gt 0 ]]; then
    echo "  Could not migrate database"
    exit 1
  else
    echo "  Migrated database"
  fi

  echo
  echo "1.8) Dumping intermediate database in version 8 ..."

  docker exec -it $MYSQL_CONTAINER mysqldump -p$MYSQL_PWD $DATABASE > $DATABASE-mysql-dump-8.sql

  if [[ $? -gt 0 ]]; then
    echo "  Could not dump database"
    exit 1
  else
    echo "  Dumped database"
  fi
fi

# STEP 2: Migrate from 8 to 10 (latest)
echo
echo "2) Migrate from 8 to 10 and from MySQL to Postgres"

if [[ "$SKIP_STEP_1" = "true" ]]; then
  # Start the MySQL database now as the first step was skipped
  echo
  echo "2.1) Starting mysql database..."
  docker ps || true
  if [[ ! `docker ps | grep $MYSQL_CONTAINER` ]]; then
    docker run --rm -p $MYSQL_PORT:3306 -d --name $MYSQL_CONTAINER -e MYSQL_ROOT_PASSWORD=$MYSQL_PWD mysql:5.6
    if [[ $? -gt 0 ]]; then exit 1; fi
    docker exec -it $MYSQL_CONTAINER mysqladmin ping -u root --password=$MYSQL_PWD --wait=30
    echo "  database started"
  else
    echo "  already running"
  fi

  echo
  echo "2.2) Creating MySQL database for migration from OP 8"
  echo "drop database if exists $DATABASE; create database $DATABASE;" | docker exec -i $MYSQL_CONTAINER mysql -p$MYSQL_PWD

  if [[ $? -gt 0 ]]; then
    echo "  Could not create database"
    exit 1
  else
    echo "  Created database"
  fi

  echo
  echo "2.3) Importing MySQL dump ($MYSQL_DUMP_FILE)"

  cat $MYSQL_DUMP_FILE | docker exec -i $MYSQL_CONTAINER mysql -p$MYSQL_PWD $DATABASE

  if [[ $? -gt 0 ]]; then
    echo "  Could not import database"
    exit 1
  else
    echo "  Imported database"
  fi
fi

echo
echo "2.4) Starting postgres database"

if [[ ! `docker ps | grep $POSTGRES_CONTAINER` ]]; then
  docker run --rm -p $POSTGRES_PORT:5432 -d --name $POSTGRES_CONTAINER -e POSTGRES_PASSWORD=postgres postgres:$POSTGRES_VERSION
  if [[ $? -gt 0 ]]; then exit 1; fi
  sleep 10
  echo "  database started"
else
  echo "  database already running"
fi

echo
echo "2.5) Migrating from MySQL to Postgres (and 8 to 10)"

docker run \
  --rm \
  -v $PWD:/data \
  --name $MIGRATE_CONTAINER \
  -e MYSQL_DATABASE_URL="mysql2://$MYSQL_USER:$MYSQL_PWD@$DOCKER_HOST_IP:$MYSQL_PORT/$DATABASE" \
  -e DATABASE_URL="postgresql://postgres:postgres@$DOCKER_HOST_IP:$POSTGRES_PORT/$DATABASE" \
  -e FORCE_YES=true \
  -t openproject/openproject:b007c71494a76924396ad0b168ba733471e3e326 \
  > migration.log &

# wait for migration to finish...
( timeout --preserve-status $MIGRATION_TIMEOUT_S tail -f -n0 migration.log & ) | grep -q "completed"
MIGRATION_STATUS=$?

if [[ $MIGRATION_STATUS -gt 0 ]]; then
  echo "  migration unsuccessful. Please check migration.log"
  exit 1
else
  echo "  migration SUCCESSFUL!"
fi

echo
echo "2.6) Moving dangling tables from $DATABASE to public"

MOVE_SCHEMA_FN=$(cat <<-SQLFUNC
CREATE OR REPLACE FUNCTION move_schema_to_public(old_schema varchar) RETURNS void LANGUAGE plpgsql VOLATILE AS
\$\$
DECLARE
    row record;
BEGIN
    FOR row IN SELECT tablename FROM pg_tables WHERE schemaname = quote_ident(old_schema)
    LOOP
        EXECUTE 'ALTER TABLE ' || quote_ident(old_schema) || '.' || quote_ident(row.tablename) || ' SET SCHEMA public;';
    END LOOP;
END;
\$\$;
SQLFUNC
)

docker exec -it $POSTGRES_CONTAINER psql \
  -U postgres \
  -d $DATABASE \
  -c "$(echo $MOVE_SCHEMA_FN); SELECT * FROM move_schema_to_public('$DATABASE'); DROP SCHEMA IF EXISTS openproject;"

if [[ $? -gt 0 ]]; then
  echo "  Could not move tables from $DATABASE to public. You may have to do this yourself."
  exit 1
else
  echo "  Moved tables from $DATABASE to public"
fi

echo
echo "2.7) Making sure needed postgres extensions are installed"

docker exec -it $POSTGRES_CONTAINER psql \
  -U postgres \
  -d $DATABASE \
  -c "create extension if not exists pg_trgm with schema public; create extension if not exists btree_gist with schema public;"

if [[ $? -gt 0 ]]; then
  echo "  Could not create postgres extensions. You may have to do this yourself."
  exit 1
else
  echo "  Created needed postgres extensions."
fi

echo
echo "2.8) Making extra sure primary keys are named correctly"

docker exec -it $MIGRATE_CONTAINER \
  bundle exec rake db:migrate:redo VERSION=20190502102512

if [[ $? -gt 0 ]]; then
  echo "  Failed to rename primary keys. You may have to do this yourself."
  exit 1
else
  echo "  Ensured correct primary key names."
fi

echo
echo "2.9) Migrating from 10 to current ($CURRENT_OP_MAJOR_VERSION)"

docker pull openproject/openproject:$CURRENT_OP_MAJOR_VERSION

docker run \
  --rm \
  -v $PWD:/data \
  --name migrate10tocurrent \
  -e DATABASE_URL="postgresql://postgres:postgres@$DOCKER_HOST_IP:$POSTGRES_PORT/$DATABASE" \
  -it openproject/openproject:$CURRENT_OP_MAJOR_VERSION \
  bundle exec rake db:migrate > migration.log

MIGRATION_STATUS=$?

if [[ $MIGRATION_STATUS -gt 0 ]]; then
  echo "  migration unsuccessful. Please check migration.log"
  exit 1
else
  echo "  migration SUCCESSFUL!"
fi

EXT="dump"
if [[ "$DUMP_FORMAT" = "sql" ]]; then
  EXT="sql"
fi

echo
echo "2.10) Dumping migrated database to $DATABASE-migrated.$EXT"

OUTPUT_PARAMS="-F custom -f /data/$DATABASE-migrated.dump"
OUTPUT_FILE="/dev/stdout"

if [[ "$DUMP_FORMAT" = "sql" ]]; then
  OUTPUT_PARAMS=""
  OUTPUT_FILE="./$DATABASE-migrated.sql"
fi

# Using the running docker image to dump the database to ensure we use the same
# postgres client version and also so that a postgres client is not necessary to run this script.
# We are not using the latest container since the Postgres version might have changed in it.
docker run \
  --rm \
  -e PGPASSWORD=postgres \
  -v /tmp:/data \
  -it openproject/openproject:$CURRENT_OP_MAJOR_VERSION pg_dump \
    -h $DOCKER_HOST_IP \
    -p $POSTGRES_PORT \
    -U postgres \
    -d $DATABASE \
    -n public \
    -x -O \
    $OUTPUT_PARAMS \
    > $OUTPUT_FILE

if [[ $? -gt 0 ]]; then
  echo "  Could not dump database"
  exit 1
else
  echo "  Dumped database"
fi

if [[ ! "$REMOVE_CONTAINERS" = "false" ]]; then
  echo
  echo "Cleaning up used docker containers..."

  docker stop $MYSQL_CONTAINER
  docker stop $POSTGRES_CONTAINER
  docker stop $MIGRATE_CONTAINER
fi

echo "Finished after $(($SECONDS / 60)) minutes."
