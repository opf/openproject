#!/usr/bin/env bash

# we need postgresql for asset precompilation
# see: https://packager.io/documentation
sudo service postgresql start

cp -f packaging/debian/conf/configuration.yml config/configuration.yml

