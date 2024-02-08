#!/bin/bash

set -e

DUMPFILE="${1:?Pass the dump file backed up from saas}"
ADMIN_PASSWORD="${2:-admin}"

dropdb tmp
createdb tmp
psql -d tmp -c "DROP SCHEMA public;"
psql -d tmp < $DUMPFILE

SCHEMA=$(psql -t -d tmp -c "select schema_name from information_schema.schemata WHERE schema_owner != 'postgres';" | tr -d '[:space:]')
echo "RENAMING $SCHEMA to public";

psql -d tmp -c "ALTER SCHEMA \"$SCHEMA\" RENAME TO \"public\";"
psql -d tmp -c "UPDATE settings SET value = 'localhost:3000' WHERE name = 'host_name'"

cat cleanup.sql | psql -d tmp

rubytmpfile=$(mktemp /tmp/cleanup-script.XXXXXX)

cat <<EOT >> $rubytmpfile
  Grids::Widget.where(identifier: 'custom_text').update_all(options: { name: "Custom title", text: 'Custom text' } )

  u = User.new login: 'admin', mail: 'admin@localhost', firstname: 'admin', lastname: 'lastname', password: $ADMIN_PASSWORD, password_confirmation: $ADMIN_PASSWORD, admin: true; u.save!(validate: false)
EOT

cd ~/openproject/dev && DATABASE_URL=postgres:///tmp bundle exec rails runner $rubytmpfile

pg_dump -Fp tmp > tmp.dump 

