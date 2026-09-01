#!/bin/bash
set -euxo pipefail

DOCKER=${DOCKER:-0}
FORCE_ASSET_RECOMPILE=${FORCE_ASSET_RECOMPILE:-0}

if [ "$FORCE_ASSET_RECOMPILE" = "1" ]; then
  echo "Forcing asset recompilation by invalidating cached manifests."
  rm -f config/frontend_assets.manifest.json db/schema_cache.yml
fi

if [ -f config/frontend_assets.manifest.json ]; then
  echo "Assets have already been precompiled. Reusing."
else
  echo "Assets need to be compiled"
  JOBS=8 npm install

  SECRET_KEY_BASE="$(openssl rand -hex 64)" RAILS_ENV=production DATABASE_URL=nulldb://db \
    bin/rails openproject:plugins:register_frontend assets:precompile

  if [ "$DOCKER" = "1" ]; then
    rm -rf /tmp/nulldb
    # Remove sprockets cache
    rm -rf "$APP_PATH/tmp/cache/assets"
    # Remove node_modules and entire frontend
    rm -rf "$APP_PATH/node_modules/" "$APP_PATH/frontend/node_modules/"
    # Remove angular cache
    rm -rf "$APP_PATH/frontend/.angular"
    # Clean cache in root
    rm -rf /root/.npm
    rm -f "$APP_PATH/log/production.log"
  fi
fi
