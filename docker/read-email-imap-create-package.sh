#!/bin/bash

set -e

while true; do
    # Ref: https://github.com/opf/openproject/blob/dev/docs/configuration/incoming-emails.md
    echo "=== Checking for new emails from IMAP ==="
    bundle exec rake redmine:email:receive_imap \
           host="imap.gmail.com" \
           username="xyz@gmail.com" \
           password="abc" \
           port="993" \
           ssl="true" \
           folder="INBOX" \
           unknown_user="${IMAP_UNKNOWN_USER}" \
           no_permission_check="0" \
           move_on_success="processed" \
           move_on_failure="not-processed" \
           allow_override="type" \
           project="incoming-from-email" \
           type="task" 
        echo "Rescheduling in 10s"
        sleep 10s
done
