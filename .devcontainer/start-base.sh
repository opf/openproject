#!/bin/bash

set -euo pipefail

screen -dmS backend bundle exec rails server -u puma -b 0.0.0.0

# We are setting FE_HOST after the backend has started os that it
# doesn't try to use 0.0.0.0 as the hostname in the HTML output.
export FE_HOST=0.0.0.0
screen -dmS frontend npm run serve
