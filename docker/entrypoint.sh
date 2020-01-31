#!/bin/bash

set -e
set -o pipefail

APACHE_PIDFILE=/run/apache2/apache2.pid

if [ -n "$DATABASE_URL" ]; then
	/usr/local/bin/migrate-mysql-to-postgres || exit 1
fi

# handle legacy configs
if [ -d "$PGDATA_LEGACY" ]; then
	echo "WARN: You are using a legacy volume path for your postgres data. You should mount your postgres volumes at $PGDATA instead of $PGDATA_LEGACY."
	if [ "$(find "$PGDATA" -type f | wc -l)" = "0" ]; then
		echo "INFO: $PGDATA is empty, so $PGDATA will be symlinked to $PGDATA_LEGACY as a temporary measure."
		sed -i "s|$PGDATA|$PGDATA_LEGACY|" /etc/postgresql/9.6/main/postgresql.conf
		export PGDATA="$PGDATA_LEGACY"
	else
		echo "ERROR: $PGDATA contains files, so we will not attempt to symlink $PGDATA to $PGDATA_LEGACY. Please fix your docker configuration."
		exit 2
	fi
fi

if [ -d "$APP_DATA_PATH_LEGACY" ]; then
	echo "WARN: You are using a legacy volume path for your openproject data. You should mount your openproject volume at $APP_DATA_PATH instead of $APP_DATA_PATH_LEGACY."
	if [ "$(find "$APP_DATA_PATH" -type f | wc -l)" = "0" ]; then
		echo "INFO: $APP_DATA_PATH is empty, so $APP_DATA_PATH will be symlinked to $APP_DATA_PATH_LEGACY as a temporary measure."
		# also set ATTACHMENTS_STORAGE_PATH back to its legacy value in case it hasn't been changed
		if [ "$ATTACHMENTS_STORAGE_PATH" = "$APP_DATA_PATH/files" ]; then
			export ATTACHMENTS_STORAGE_PATH="$APP_DATA_PATH_LEGACY/files"
		fi
		export APP_DATA_PATH="$APP_DATA_PATH_LEGACY"
	else
		echo "ERROR: $APP_DATA_PATH contains files, so we will not attempt to symlink $APP_DATA_PATH to $APP_DATA_PATH_LEGACY. Please fix your docker configuration."
		exit 2
	fi
fi

if [ "$(id -u)" = '0' ]; then
	mkdir -p $APP_DATA_PATH/{files,git,svn}
	chown -R $APP_USER:$APP_USER $APP_DATA_PATH /etc/apache2/sites-enabled/

	# Clean up any dangling PID file
	rm -f $APP_PATH/tmp/pids/*

	# Clean up a dangling PID file of apache
	if [ -e "$APACHE_PIDFILE" ]; then
	  rm -f $APACHE_PIDFILE || true
	fi

	# Fix assets path if relative URL is used
	relative_url_root_without_trailing_slash="$(echo $OPENPROJECT_RAILS__RELATIVE__URL__ROOT | sed 's:/*$::')"
	if [ "$relative_url_root_without_trailing_slash" != "" ]; then
		for file in $(egrep -lR "/assets/" "$APP_PATH/public"); do
			# only the font paths in the CSSs need updating
			sed -i "s|/assets/|${relative_url_root_without_trailing_slash}/assets/|g" $file
			# the .gz is the one served by puma, so rebuild it
			gzip --force --keep $file
		done
	fi

	if [ ! -z "$ATTACHMENTS_STORAGE_PATH" ]; then
		mkdir -p "$ATTACHMENTS_STORAGE_PATH"
		chown -R "$APP_USER:$APP_USER" "$ATTACHMENTS_STORAGE_PATH"
	fi
	mkdir -p "$APP_PATH/log" "$APP_PATH/tmp/pids" "$APP_PATH/files"
	chown "$APP_USER:$APP_USER" "$APP_PATH"
	chown -R "$APP_USER:$APP_USER" "$APP_PATH/log" "$APP_PATH/tmp" "$APP_PATH/files" "$APP_PATH/public"
	if [ "$1" = "./docker/supervisord" ] || [ "$1" = "./docker/proxy" ]; then
		exec "$@"
	else
		exec $APP_PATH/docker/gosu $APP_USER "$BASH_SOURCE" "$@"
	fi
fi

exec "$@"
