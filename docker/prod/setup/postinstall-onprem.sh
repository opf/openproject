#!/bin/bash
set -eox pipefail


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

apt-get update -qq
# embed all-in-one additional software
apt-get install -y  \
	postgresql-$CURRENT_PGVERSION \
	postgresql-$NEXT_PGVERSION \
	memcached \
	postfix \
	apache2 \
	supervisor \
	git subversion \
	wget

# remove any existing cluster
service postgresql stop
rm -rf /var/lib/postgresql/{$CURRENT_PGVERSION,$NEXT_PGVERSION}

a2enmod proxy proxy_http
rm -f /etc/apache2/sites-enabled/000-default.conf

# gosu
dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"
wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"
chmod +x /usr/local/bin/gosu
gosu nobody true

apt-get purge -y wget
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
truncate -s 0 /var/log/*log
