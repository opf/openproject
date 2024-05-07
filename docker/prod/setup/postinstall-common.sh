#!/bin/bash
set -eox pipefail

# Ensure we can write in /tmp/op_uploaded_files (cf. #29112)
mkdir -p /tmp/op_uploaded_files/ && chown -R $APP_USER:$APP_USER /tmp/op_uploaded_files/

# Remove any existing config/database.yml
rm -f ./config/database.yml