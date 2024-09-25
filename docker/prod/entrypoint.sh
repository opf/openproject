#!/bin/bash

set -e
set -o pipefail

APACHE_PIDFILE=/run/apache2/apache2.pid

# Use jemalloc at runtime
if [ "$USE_JEMALLOC" = "true" ]; then
	export LD_PRELOAD=libjemalloc.so.2
fi

# handle legacy configs
if [ -f "/var/lib/postgresql/9.6/main/PG_VERSION" ]; then
	echo "ERROR: You are using a legacy volume path for your postgres data. You should mount your postgres volumes at $PGDATA instead of /var/lib/postgresql/9.6/main"
	exit 2
fi
if [ -d "/var/db/openproject" ]; then
	echo "ERROR: You are using a legacy volume path for your openproject data. You should mount your openproject volume at $APP_DATA_PATH instead of /var/db/openproject"
	exit 2
fi

if [ "$(id -u)" = '0' ]; then
	# reexport PGVERSION and PGBIN env variables according to postgres version of existing cluster (if any)
	# this must happen in the entrypoint
	if [ -f "$PGDATA/PG_VERSION" ]; then
		export PGVERSION="$(cat "$PGDATA/PG_VERSION")"
		echo "-----> Existing PostgreSQL cluster found in $PGDATA."
	fi
	export PGBIN="/usr/lib/postgresql/$PGVERSION/bin"
	export PGCONF_FILE="/etc/postgresql/$PGVERSION/main/postgresql.conf"
	echo "-----> Setting PGVERSION=$PGVERSION PGBIN=$PGBIN PGCONF_FILE=$PGCONF_FILE"
	export PATH="$PGBIN:$PATH"

	mkdir -p $APP_DATA_PATH/{files,git,svn}
	# The $APP_DATA_PATH may be hosted on a NAS that creates snapshots (or a btrfs filesystem). In such a case, the .snapshot folder cannot be touched.
  find $APP_DATA_PATH | grep -v .snapshot | xargs -n 1 chown $APP_USER:$APP_USER
	if [ -d /etc/apache2/sites-enabled ]; then
		chown -R $APP_USER:$APP_USER /etc/apache2/sites-enabled
		echo "OpenProject currently expects to be reached on the following domain: ${SERVER_NAME:=localhost}, which does not seem to be how your installation is configured." > /var/www/html/index.html
		echo "If you are an administrator, please ensure you have correctly set the SERVER_NAME variable when launching your container." >> /var/www/html/index.html
	fi

	# Clean up any dangling PID file
	rm -f $APP_PATH/tmp/pids/*

	# Clean up a dangling PID file of apache
	if [ -e "$APACHE_PIDFILE" ]; then
	  rm -f $APACHE_PIDFILE || true
	fi

	# Use ATTACHMENTS_STORAGE_PATH value when OPENPROJECT_ATTACHMENTS__STORAGE__PATH is not set
	export OPENPROJECT_ATTACHMENTS__STORAGE__PATH=${OPENPROJECT_ATTACHMENTS__STORAGE__PATH:-$ATTACHMENTS_STORAGE_PATH}
	unset ATTACHMENTS_STORAGE_PATH

	if [ ! -z "$OPENPROJECT_ATTACHMENTS__STORAGE__PATH" ]; then
		mkdir -p "$OPENPROJECT_ATTACHMENTS__STORAGE__PATH"
		chown -R "$APP_USER:$APP_USER" "$OPENPROJECT_ATTACHMENTS__STORAGE__PATH"
	fi
	mkdir -p "$APP_PATH/log" "$APP_PATH/tmp/pids" "$APP_PATH/files"
	chown "$APP_USER:$APP_USER" "$APP_PATH"
	chown -R "$APP_USER:$APP_USER" "$APP_PATH/log" "$APP_PATH/tmp" "$APP_PATH/files" "$APP_PATH/public"

	# allow to launch any command as root by prepending it with 'root'
	if [ "$1" = "root" ]; then
		shift
		exec "$@"
	fi

	if [ "$1" = "./docker/prod/supervisord" ] || [ "$1" = "./docker/prod/proxy" ]; then
		exec "$@"
	fi

	exec gosu $APP_USER "$BASH_SOURCE" "$@"
fi

exec "$@"
