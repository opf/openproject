#!/bin/bash
set -e
set -o pipefail

echo " ---> PREINSTALL"

display_error() {
	echo " !--> ERROR on preinstall:"
	tail -n 200 /tmp/dockerize.log
	exit 1
}

echo " ---> Setting up common dependencies. This will take a while..."
./docker/setup/prod/preinstall-common.sh > /tmp/dockerize.log || display_error

if test -f ./docker/setup/prod/preinstall-$PLATFORM.sh ; then
	echo " ---> Executing preinstall for $PLATFORM..."
	./docker/setup/prod/preinstall-$PLATFORM.sh >/tmp/dockerize.log || display_error
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

rm -f /tmp/dockerize.log
echo "      OK."
