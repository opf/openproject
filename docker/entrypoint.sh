#!/bin/bash

set -e
set -o pipefail

if [ "$(id -u)" = '0' ]; then
	if [ ! -z "$ATTACHMENTS_STORAGE_PATH" ]; then
		mkdir -p "$ATTACHMENTS_STORAGE_PATH"
		chown -R "$APP_USER:$APP_USER" "$ATTACHMENTS_STORAGE_PATH"
	fi
	mkdir -p "$APP_PATH/log" "$APP_PATH/tmp/pids" "$APP_PATH/files"
	chown "$APP_USER:$APP_USER" "$APP_PATH"
	chown -R "$APP_USER:$APP_USER" "$APP_PATH/log" "$APP_PATH/tmp" "$APP_PATH/files" "$APP_PATH/public"
	if [ "$1" = "./docker/supervisord" ]; then
		exec "$@"
	else
		exec $APP_PATH/docker/gosu $APP_USER "$BASH_SOURCE" "$@"
	fi
fi

exec "$@"
