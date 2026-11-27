#!/bin/sh

set -euo pipefail

apk add --no-cache ca-certificates
cp /step/certs/root_ca.crt /cacert/root_ca.crt
cat /etc/ssl/certs/ca-certificates.crt /step/certs/root_ca.crt > /cacert/ca-certificates.crt
cp /cacert/ca-certificates.crt /cacert/ca-bundle.crt

chmod 0644 /cacert/*
