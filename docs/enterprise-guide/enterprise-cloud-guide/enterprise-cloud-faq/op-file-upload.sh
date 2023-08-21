#!/bin/bash

DOMAIN=$1
API_KEY=$2
WP_ID=$3
FILE_PATH=$4

if [ -z "$DOMAIN" ] || [ -z "$API_KEY" ] || [ -z "$WP_ID" ] || [ -z "FILE_PATH" ]; then
  echo
  echo "Usage: "
  echo
  echo "  bash op-file-upload.sh <domain> <api-key> <work package ID> <file path>"
  echo
  echo "Example: "
  echo
  echo "  bash op-file-upload.sh my.openproject.com 1d58c380e10b211b9535f47e1fd8c34fa2a93187c87b3561dc33454888cca882 1141 /home/me/Pictures/logo.png"
  echo
  echo "This will upload the file 'logo.png' as an attachment to the work package with the ID 1141."
  echo "You have to create the work package beforehand using your browser (e.g. https://my.openproject.com/work_packages/new)"
  echo
  echo "You can create an API key on the OpenProject console (\`sudo openproject run console\`) like this: "
  echo
  echo "  puts Token::API.create!(user: User.find_by(login: 'm.user@openproject.com')).plain_value; exit"
  echo
  echo "Where \"m.user@openproject.com\" would be your user's login in your OpenProject environment."
  echo "Alternatively you can simply create the API key using your browser under My Account -> Access Tokens -> API."

  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "Could not find file '$FILE_PATH'"
  exit 1
fi

FILE_NAME=`basename $FILE_PATH`
CONTENT_TYPE=`file --mime-type $FILE_PATH | cut -d: -f2 | tr -d ' '`

curl "https://$DOMAIN/api/v3/work_packages/$WP_ID/attachments" \
  -u "apikey:$API_KEY" \
  -H 'accept: application/json, text/plain, */*' \
  -F "metadata={\"fileName\":\"$FILE_NAME\",\"contentType\":\"$CONTENT_TYPE\"}" \
  -F "file=@$FILE_PATH" \
  > .op-file-upload-output.json

cat .op-file-upload-output.json
