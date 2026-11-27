#!/bin/bash

set -euo pipefail

apk add --no-cache ca-certificates
cat /etc/ssl/certs/ca-certificates.crt /step/certs/root_ca.crt > /cacert/ca-certificates.crt
cp /cacert/ca-certificates.crt /cacert/ca-bundle.crt
