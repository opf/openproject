#!/bin/bash
set -euxo pipefail

# Ensure we can write in /tmp/op_uploaded_files (cf. #29112)
mkdir -p /tmp/op_uploaded_files/ && chown -R $APP_USER:$APP_USER /tmp/op_uploaded_files/

# Install the IFC -> xeokit metadata extractor (BIM edition only).
# preinstall-common.sh has already pulled in node + npm for BIM; here, with
# the application source available at /app, we install the extension's runtime
# dependencies and expose its CLI on PATH.
EXT_DIR=/app/extensions/web-ifc-xeokit-metadata
if command -v npm >/dev/null 2>&1 && [ -d "$EXT_DIR" ]; then
  (cd "$EXT_DIR" && npm install --omit=dev --no-audit --no-fund)
  chown -R $APP_USER:$APP_USER "$EXT_DIR/node_modules"
  cat > /usr/local/bin/web-ifc-xeokit-metadata <<EOF
#!/bin/sh
exec "$EXT_DIR/node_modules/.bin/tsx" "$EXT_DIR/src/index.ts" "\$@"
EOF
  chmod +x /usr/local/bin/web-ifc-xeokit-metadata
fi

# Remove any existing config/database.yml
rm -f ./config/database.yml

# We need this so puma is allowed to create the tmp/pids folder and
# temporary upload files when running with a uid other than 1000 (app)
# but with an allowed supplemental group (1000).
tmp_path="$APP_PATH/tmp"
# Remove any previously cached files from e.g., asset building
rm -rf "$tmp_path"
# Recreate and own it for the user for later files (PID etc. see above)
mkdir -p "$tmp_path"
chown -R $APP_USER:$APP_USER "$tmp_path"
chmod g+rw "$tmp_path"
