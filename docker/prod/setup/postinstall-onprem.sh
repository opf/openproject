#!/bin/bash
set -euxo pipefail

apt-get update -qq

# postfix.postinst tries to generate a hostname based on /etc/resolv.conf, which
# gets copied in to the docker environment from the host system. On systems
# that are not on a network with a domain, this will result in a failed install.
#
# See https://salsa.debian.org/postfix-team/postfix-dev/-/blob/debian/buster-updates/debian/postfix.postinst#L40
if [ -f /run/.containerenv -o -f /.dockerenv ]; then
	mv /bin/hostname /bin/x-hostname
	echo openproject.local > /etc/hostname
	apt-get install -y postfix
	mv /bin/x-hostname /bin/hostname
fi

# embed all-in-one additional software
apt-get install -y  \
	memcached \
	postfix \
	apache2 \
	supervisor \
	git subversion \
	wget

# Install postgres server versions
for version in $PGVERSION_CHOICES ; do
	apt-get install -yq --no-install-recommends postgresql-$version
done

# remove any existing cluster
service postgresql stop
for version in $PGVERSION_CHOICES ; do
	rm -rf /var/lib/postgresql/{$version}
done

a2enmod proxy proxy_http
rm -f /etc/apache2/sites-enabled/000-default.conf

rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
truncate -s 0 /var/log/*log
