#!/bin/bash
set -e
set -o pipefail

apt-get install -y  \
	memcached \
	postfix \
	apache2 \
	supervisor

a2enmod proxy proxy_http
rm -f /etc/apache2/sites-enabled/000-default.conf
