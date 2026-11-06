#!/bin/bash

set -euo pipefail

sudo mkdir -p "/home/${USER}/openproject/tmp"
sudo chown "${USER}:${USER}" "/home/${USER}/openproject/tmp"
sudo chmod 0777 "/home/${USER}/openproject/tmp"

cat >"/home/${USER}/openproject/config/database.yml" <<EOF
development:
  adapter: postgresql
  url: ${OPENPROJECT_DB_URL}
  encoding: unicode
  pool: 20
EOF

export MAKE
MAKE="make --jobs $(nproc)"

bundle install --jobs "$(nproc)"
bundle exec rake db:create db:migrate
bundle exec rake db:seed
bundle exec rake openproject:plugins:register_frontend
bundle exec rake assets:export_locales

rm -rf "/home/${USER}/openproject/tmp/*"

cd frontend
npm i

