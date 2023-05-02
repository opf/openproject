#!/bin/bash

set -e
set -o pipefail

pushd "${APP_PATH}/frontend"

export NG_CLI_ANALYTICS=ci # so angular cli doesn't block waiting for user input
export JOBS=2
export PGBIN="$(pg_config --bindir)"

# Ensure we can write in /tmp/op_uploaded_files (cf. #29112)
mkdir -p /tmp/op_uploaded_files/ && chown -R $APP_USER:$APP_USER /tmp/op_uploaded_files/

rm -f ./config/database.yml

# Installing frontend dependencies
npm set cache /var/cache/npm
npm install

popd

# Bundle assets
su - postgres -c "$PGBIN/initdb -D /tmp/nulldb"
su - postgres -c "$PGBIN/pg_ctl -D /tmp/nulldb -l /dev/null -w start"
echo "create database assets; create user assets with encrypted password 'p4ssw0rd'; grant all privileges on database assets to assets;" | su - postgres -c psql

# give some more time for DB to start
sleep 5

# dump schema
DATABASE_URL=postgres://assets:p4ssw0rd@127.0.0.1/assets RAILS_ENV=production bundle exec rake db:migrate db:schema:dump db:schema:cache:dump

# this line requires superuser rights, which is not always available and doesn't matter anyway
sed -i '/^COMMENT ON EXTENSION/d' db/structure.sql

# precompile assets
DATABASE_URL=postgres://assets:p4ssw0rd@127.0.0.1/assets RAILS_ENV=production bundle exec rake assets:precompile
rm -rf $APP_PATH/frontend/src $APP_PATH/frontend/src/package-lock.json

su - postgres -c "$PGBIN/pg_ctl -D /tmp/nulldb stop"

rm -rf /tmp/nulldb

# Remove sprockets cache
rm -rf "$APP_PATH/tmp/cache/assets"
rm -f "$APP_PATH/log/production.log"

mkdir -p "$APP_PATH/log" "$APP_PATH/tmp/pids" "$APP_PATH/files"
chown -R $APP_USER.$APP_USER "$APP_PATH/log" "$APP_PATH/tmp" "$APP_PATH/files"

cat > "$APP_PATH/config/database.yml" <<CONF
production:
  url: <%= ENV.fetch("DATABASE_URL") %>
  variables:
    # https://github.com/ankane/the-ultimate-guide-to-ruby-timeouts#postgresql
    statement_timeout: <%= ENV.fetch("POSTGRES_STATEMENT_TIMEOUT", "90s") %>
CONF
