#!/bin/bash
set -e

pushd "${APP_PATH}/frontend"

# Installing frontend dependencies
RAILS_ENV=production npm install

popd

# Bundle assets
DATABASE_URL='nulldb://nohost' RAILS_ENV=production bundle exec rake assets:precompile

# Remove node_modules and entire frontend
rm -rf "$APP_PATH/node_modules/" "$APP_PATH/frontend/node_modules/"

# Clean cache in root
rm -rf /root/.npm
