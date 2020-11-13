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
./docker/prod/setup/preinstall-common.sh > /tmp/dockerize.log || display_error

if test -f ./docker/prod/setup/preinstall-$PLATFORM.sh ; then
	echo " ---> Executing preinstall for $PLATFORM..."
	./docker/prod/setup/preinstall-$PLATFORM.sh >/tmp/dockerize.log || display_error
fi

apt-get clean
rm -rf /var/lib/apt/lists/*

rm -f /tmp/dockerize.log
echo "      OK."
