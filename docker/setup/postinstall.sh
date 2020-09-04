#!/bin/bash

set -e

PGBIN="$(pg_config --bindir)"

display_error() {
	echo " !--> ERROR on postinstall:"
	tail -n 200 /tmp/dockerize.log
	exit 1
}

echo " ---> POSTINSTALL"

# Add MySQL-to-Postgres migration script to path (used in entrypoint.sh)
cp ./docker/mysql-to-postgres/bin/migrate-mysql-to-postgres /usr/local/bin/

# Ensure we can write in /tmp/op_uploaded_files (cf. #29112)
mkdir -p /tmp/op_uploaded_files/ && chown -R $APP_USER:$APP_USER /tmp/op_uploaded_files/

rm -f ./config/database.yml

if test -f ./docker/setup/postinstall-$PLATFORM.sh ; then
	echo " ---> Executing postinstall for $PLATFORM..."
	./docker/setup/postinstall-$PLATFORM.sh
fi

echo " ---> Precompiling assets. This will take a while..."

(
	pushd "${APP_PATH}/frontend"

	export NG_CLI_ANALYTICS=ci # so angular cli doesn't block waiting for user input

	# Installing frontend dependencies
	RAILS_ENV=production npm install

	popd

	# Bundle assets
	su - postgres -c "$PGBIN/initdb -D /tmp/nulldb"
	su - postgres -c "$PGBIN/pg_ctl -D /tmp/nulldb -l /dev/null -w start"
	echo "create database assets; create user assets with encrypted password 'p4ssw0rd'; grant all privileges on database assets to assets;" | su - postgres -c psql
	DATABASE_URL=postgres://assets:p4ssw0rd@127.0.0.1/assets RAILS_ENV=production bundle exec rake db:migrate db:schema:dump db:schema:cache:dump assets:precompile

	su - postgres -c "$PGBIN/pg_ctl -D /tmp/nulldb stop"

	rm -rf /tmp/nulldb

	# Remove sprockets cache
	rm -rf "$APP_PATH/tmp/cache/assets"

	# Remove node_modules and entire frontend
	rm -rf "$APP_PATH/node_modules/" "$APP_PATH/frontend/node_modules/"

	# Clean cache in root
	rm -rf /root/.npm
) >/tmp/dockerize.log || display_error

rm -f /tmp/dockerize.log
echo "      OK."
