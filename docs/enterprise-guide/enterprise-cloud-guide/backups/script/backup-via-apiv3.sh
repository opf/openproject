#!/bin/bash

#Scope is to pull a backup from an OpenProject Enterprise on-premises or cloud installation and download it to a local path
#This is done by using the APIv3, so variable api_key is mandatory to be changed.
#The backup logic needs you to create a token and after you created the token you have change the backup_token variable, too.

#VERBOSE LOGGING
#set -x

domain=foo.openproject.com
api_key=bar
backup_token=baz

set -e

curl \
  -X POST \
  -u apikey:$api_key \
  https://$domain/api/v3/backups \
  -H 'content-type: application/json' \
  --data-raw "{\"backupToken\":\"$backup_token\",\"attachments\":false}" \
  > response.json

status_path="`cat response.json | jq -r ._links.job_status.href`"
status_url="https://$domain$status_path"

while true; do
  curl -s -u apikey:$api_key $status_url > response.json

  if [[ "`cat response.json | jq .status`" != '"success"' ]]; then
    echo 'waiting for download'
    sleep 5
  else
    echo 'download ready'
    break
  fi
done

download_path=`cat response.json | jq -r .payload.download`
download_url="https://$domain$download_path"

curl -u apikey:$api_key -L $download_url > "openproject-`date | tr ' ' '-' | tr ':' '-'`.zip"

echo "download complete"

