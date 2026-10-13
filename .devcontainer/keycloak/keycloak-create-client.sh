#!/bin/bash

set -euo pipefail

keytool -importcert -noprompt \
  -alias ca-certificates \
  -file /etc/ssl/certs/ca-certificates.crt \
  -keystore /tmp/kcadm-truststore.p12 -storetype PKCS12 \
  -storepass changeme

/opt/keycloak/bin/kcadm.sh config truststore \
  --trustpass changeme /tmp/kcadm-truststore.p12

ID=$(/opt/keycloak/bin/kcadm.sh get clients --no-config --server "${KEYCLOAK_URL}" --realm master --user admin --password admin -q "clientId=${OPENPROJECT_OPENID__CONNECT_KEYCLOAK_IDENTIFIER}" --fields id --format csv --noquotes || true)
if [ -z "${ID}" ]; then
  /opt/keycloak/bin/kcadm.sh create clients \
        --no-config --server "${KEYCLOAK_URL}" \
        --realm master \
        --user admin \
        --password admin \
        -s "clientId=${OPENPROJECT_OPENID__CONNECT_KEYCLOAK_IDENTIFIER}" \
        -s "secret=${OPENPROJECT_OPENID__CONNECT_KEYCLOAK_SECRET}" \
        -s publicClient=false \
        -s "redirectUris=[\"${OPENPROJECT_OPENID__CONNECT_KEYCLOAK_REDIRECT_URI}\"]"
fi
