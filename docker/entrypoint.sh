#!/bin/bash

set -e
set -o pipefail

PGDATA=${PGDATA:=/var/lib/postgresql/9.6/main}
PGUSER=${PGUSER:=postgres}
PGPASSWORD=${PGPASSWORD:=postgres}
PG_STARTUP_WAIT_TIME=${PG_STARTUP_WAIT_TIME:=10}
SUPERVISORD_LOG_LEVEL=${SUPERVISORD_LOG_LEVEL:=info}
PGBIN="/usr/lib/postgresql/9.6/bin"

if [ ! -z "$ATTACHMENTS_STORAGE_PATH" ]; then
	mkdir -p "$ATTACHMENTS_STORAGE_PATH"
	chown -R app:app "$ATTACHMENTS_STORAGE_PATH"
fi

if [ "$(id -u)" = '0' ]; then
    echo "-----> Ensure $APP_PATH is owned by $APP_USER"
	mkdir -p "$APP_PATH/log" "$APP_PATH/tmp" "$APP_PATH/files"
	chown $APP_USER:$APP_USER "$APP_PATH"
	chown -R $APP_USER:$APP_USER "$APP_PATH/log" "$APP_PATH/tmp" "$APP_PATH/files" "$APP_PATH/public"
fi

dbhost=$(ruby -ruri -e 'puts URI(ENV.fetch("DATABASE_URL")).host')
pwfile=$(mktemp)
echo "$PGPASSWORD" > $pwfile
chown postgres $pwfile

PLUGIN_GEMFILE_TMP=$(mktemp)
PLUGIN_GEMFILE=/usr/src/app/Gemfile.local

if [ "$PLUGIN_GEMFILE_URL" != "" ]; then
	echo "Fetching custom gemfile from ${PLUGIN_GEMFILE_URL}..."
	curl -L -o "$PLUGIN_GEMFILE_TMP" "$PLUGIN_GEMFILE_URL"

	# set custom plugin gemfile if file is readable and non-empty
	if [ -s "$PLUGIN_GEMFILE_TMP" ]; then
		mv "$PLUGIN_GEMFILE_TMP" "$PLUGIN_GEMFILE"
		chown $APP_USER:$APP_USER "$PLUGIN_GEMFILE"
	fi
fi

indent() {
	sed -u 's/^/       /'
}

install_plugins() {
	pushd /usr/src/app

	if [ -s "$PLUGIN_GEMFILE" ]; then
		echo "Installing plugins..."
		bundle install

		echo "Installing frontend dependencies..."
		pushd /usr/src/app/frontend
		if [ "$(id -u)" = '0' ]; then
			su - $APP_USER -c "cd $APP_PATH/frontend && npm install"
		else
			npm install
		fi
		popd


		echo "Precompiling new assets..."
		bundle exec rake assets:precompile

		echo "Plugins installed"
	fi

	popd
}

migrate() {
	wait_for_postgres
	pushd /usr/src/app
	/etc/init.d/memcached start
	bundle exec rake db:migrate db:seed db:structure:dump
	/etc/init.d/memcached stop
	chown app:app db/structure.sql
	popd
}

wait_for_postgres() {
	retries=${PG_STARTUP_WAIT_TIME}

	echo "Trying to contact PostgreSQL server instance or waiting for it to come online."

	until su postgres -c "$PGBIN/psql $DATABASE_URL -c 'select 1;' > /dev/null 2>&1" || [ $retries -eq 0 ]; do
		echo "Waiting for postgres server, $((retries--)) remaining attempts..."
		sleep 3
	done
}

if [ "$dbhost" = "127.0.0.1" ]; then
	# initialize cluster if it does not exist yet
	if [ -f "$PGDATA/PG_VERSION" ]; then
		echo "-----> Database cluster already exists, not modifying."
		/etc/init.d/postgresql start | indent
		(install_plugins && migrate) | indent
		/etc/init.d/postgresql stop | indent
	else
		echo "-----> Database cluster not found. Creating a new one in $PGDATA..."
		chown -R postgres:postgres $PGDATA
		su postgres -c "$PGBIN/initdb --pgdata=${PGDATA} --username=${PGUSER} --encoding=unicode --auth=trust --pwfile=$pwfile" | indent
		su postgres -c "rm -f $pwfile"
		/etc/init.d/postgresql start | indent
		su postgres -c "$PGBIN/psql --command \"CREATE USER openproject WITH SUPERUSER PASSWORD 'openproject';\"" | indent
		su postgres -c "$PGBIN/createdb -O openproject openproject" | indent
		(install_plugins && migrate) | indent
		/etc/init.d/postgresql stop | indent
	fi
else
	echo "-----> You're using an external database. Not initializing a local database cluster."
	migrate | indent
fi

echo "-----> Database setup finished."
echo "       On first installation, the default admin credentials are login: admin, password: admin"

echo "-----> Launching supervisord..."
exec /usr/bin/supervisord -e ${SUPERVISORD_LOG_LEVEL}

