#!/bin/bash

set -euxo pipefail

APP_PATH=${APP_PATH:-/app}

# Remove source-only trees that are not needed for slim runtime images.
rm -rf \
  "$APP_PATH/spec" \
  "$APP_PATH/screenshots" \
  "$APP_PATH/lookbook" \
  "$APP_PATH/frontend"

# Keep precompiled enterprise media in public/assets and remove duplicate source videos.
if [ -d "$APP_PATH/public/assets/enterprise" ]; then
  rm -rf "$APP_PATH/app/assets/videos/enterprise"
fi

# Source maps are useful during development, but unnecessary in slim runtime images.
find "$APP_PATH/public/assets" -type f -name '*.map' -delete

# Lookbook source is removed above, so its compiled static assets are unnecessary too.
rm -rf "$APP_PATH/public/assets/lookbook"

# Module test and documentation folders are not used at runtime.
find "$APP_PATH/modules" -mindepth 2 -maxdepth 2 -type d \
  \( -name spec -o -name test -o -name tests -o -name doc -o -name docs \) \
  -prune -exec rm -rf '{}' +

# Remove leftover git metadata and common non-runtime folders from vendored git gems.
for gem_root in "$APP_PATH/vendor/bundle"/ruby/*/gems "$APP_PATH/vendor/bundle"/ruby/*/bundler/gems; do
  [ -d "$gem_root" ] || continue
  rm -rf "$gem_root"/*/.git
  rm -rf "$gem_root"/*/{doc,docs,example,examples,benchmark,benchmarks}
done

# Remove static/object files left by native builds.
find "$APP_PATH/vendor/bundle" -type f \( -name '*.a' -o -name '*.o' \) -delete
