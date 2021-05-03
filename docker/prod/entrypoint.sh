#!/bin/bash

set -e
set -o pipefail

APACHE_PIDFILE=/run/apache2/apache2.pid

# handle legacy configs
if [ -f "/var/lib/postgresql/9.6/main/PG_VERSION" ]; then
	echo "WARN: You are using a legacy volume path for your postgres data. You should mount your postgres volumes at $PGDATA instead of /var/lib/postgresql/9.6/main"
	exit 2
fi
if [ -d "/var/db/openproject" ]; then
	echo "WARN: You are using a legacy volume path for your openproject data. You should mount your openproject volume at $APP_DATA_PATH instead of /var/db/openproject"
	exit 2
fi

if [ "$(id -u)" = '0' ]; then
	mkdir -p $APP_DATA_PATH/{files,git,svn}
	chown -R $APP_USER:$APP_USER $APP_DATA_PATH
	if [ -d /etc/apache2/sites-enabled ]; then
		chown -R $APP_USER:$APP_USER /etc/apache2/sites-enabled
	fi

	# Clean up any dangling PID file
	rm -f $APP_PATH/tmp/pids/*

	# Clean up a dangling PID file of apache
	if [ -e "$APACHE_PIDFILE" ]; then
	  rm -f $APACHE_PIDFILE || true
	fi

	if [ ! -z "$ATTACHMENTS_STORAGE_PATH" ]; then
		mkdir -p "$ATTACHMENTS_STORAGE_PATH"
		chown -R "$APP_USER:$APP_USER" "$ATTACHMENTS_STORAGE_PATH"
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

	exec $APP_PATH/docker/prod/gosu $APP_USER "$BASH_SOURCE" "$@"
fi

exec "$@"
