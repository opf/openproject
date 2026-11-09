#!/bin/bash
set -euxo pipefail

PGDATA_TMP=/tmp/schema-dump-db

echo "PGBIN: $PGBIN"

su - postgres -c "$PGBIN/initdb -D $PGDATA_TMP -E UTF8"
su - postgres -c "$PGBIN/pg_ctl -D $PGDATA_TMP -l $PGDATA_TMP/log -w start"

echo "create database structure; create user structure with encrypted password 'p4ssw0rd'; grant all privileges on database structure to structure;" | su - postgres -c psql
# since postgres 15 we need to also explicitly grant the user permissions on the public schema
echo "grant all on schema public to structure;" | su - postgres -c 'psql -d structure'

DATABASE_URL=postgres://structure:p4ssw0rd@127.0.0.1/structure RAILS_ENV=production \
  bundle exec rake db:migrate db:schema:dump db:schema:cache:dump

# this line requires superuser rights, which is not always available and doesn't matter anyway
sed -i '/^COMMENT ON EXTENSION/d' db/structure.sql

su - postgres -c "$PGBIN/pg_ctl -D $PGDATA_TMP -w stop"
rm -rf "$PGDATA_TMP" "$APP_PATH/log/production.log"
