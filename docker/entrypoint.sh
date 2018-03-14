#!/bin/bash
set -e

if [ "$ALL_IN_ONE" = "1" ]; then
	exec ./entrypoint-all-in-one.sh "$@"
fi

if [ "$(id -u)" = '0' ]; then
	chown -R $APP_USER:$APP_USER $APP_PATH $APP_DATA /usr/local
	sync
	exec $APP_PATH/docker/gosu $APP_USER "$BASH_SOURCE" "$@"
fi

mkdir -p "$ATTACHMENTS_STORAGE_PATH"
chown -R "$(id -u)" "$ATTACHMENTS_STORAGE_PATH" 2>/dev/null || :
exec "$@"
