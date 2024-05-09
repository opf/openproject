#!/bin/bash
set -eox pipefail

# Ensure we can write in /tmp/op_uploaded_files (cf. #29112)
mkdir -p /tmp/op_uploaded_files/ && chown -R $APP_USER:$APP_USER /tmp/op_uploaded_files/

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
