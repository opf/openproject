#
# License: MIT (see https://github.com/basiszwo/scripts/blob/master/LICENSE)
# File taken from https://github.com/codeship/scripts
#   see https://github.com/codeship/scripts/blob/master/packages/firefox.sh
#

#!/bin/bash
# Install a custom version of Firefox, https://www.mozilla.org/en-US/firefox/new/
#
# Add at least the following environment variables to your project configuration
# (otherwise the defaults below will be used).
# * FIREFOX_VERSION
#
# Include in your builds via
# \curl -sSL https://raw.githubusercontent.com/codeship/scripts/master/packages/firefox.sh | bash -s
FIREFOX_VERSION=${FIREFOX_VERSION:="41.0"}
FIREFOX_DIR=${FIREFOX_DIR:="$HOME/firefox"}

# fail the script on the first failing command.
set -e
CACHED_DOWNLOAD="${HOME}/cache/firefox-${FIREFOX_VERSION}.tar.bz2"

rm -rf "${FIREFOX_DIR}"
mkdir -p ${FIREFOX_DIR}
wget --continue --output-document "${CACHED_DOWNLOAD}" "https://ftp.mozilla.org/pub/mozilla.org/firefox/releases/${FIREFOX_VERSION}/linux-x86_64/en-US/firefox-${FIREFOX_VERSION}.tar.bz2"
tar -xaf "${CACHED_DOWNLOAD}" --strip-components=1 --directory "${FIREFOX_DIR}"
