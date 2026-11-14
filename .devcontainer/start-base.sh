#!/bin/bash

set -euo pipefail

screen -dmS backend bundle exec rails server -u puma -b 0.0.0.0
screen -dmS frontend npm run serve
