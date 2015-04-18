#!/usr/bin/env ruby

DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --force-yes slapd ldap-utils

TOP_DIR=`dirname $0`/../..

sudo /etc/init.d/slapd stop

# sudo cp -v /var/lib/ldap/DB_CONFIG ./DB_CONFIG
sudo rm -rf /etc/ldap/slapd.d/*
sudo rmdir  /etc/ldap/slapd.d/
sudo rm -rf /var/lib/ldap/*

sudo cp ${TOP_DIR}/test/fixtures/ldap/slapd.conf /etc/ldap/slapd.conf
sudo slaptest -u -v -f /etc/ldap/slapd.conf

# sudo cp -v ./DB_CONFIG /var/lib/ldap/DB_CONFIG

sudo /etc/init.d/slapd start

sudo ldapadd -x -D "cn=Manager,dc=redmine,dc=org" \
   -w secret -h localhost -p 389 -f ${TOP_DIR}/test/fixtures/ldap/test-ldap.ldif
