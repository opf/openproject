#!/usr/bin/env bash
# Creates the Cloud Run job + Cloud Scheduler trigger for the daily Control Center directory sync.
# Usage: IMAGE=<image> SERVICE_ACCOUNT=<sa email> VPC=<vpc> SUBNET=<subnet> docker/herfy/sync-job.sh
set -euo pipefail

: "${IMAGE:?}" "${SERVICE_ACCOUNT:?}" "${VPC:?}" "${SUBNET:?}"
REGION=${REGION:-us-central1}
PROJECT=${PROJECT:-herfy-production}

gcloud run jobs deploy openproject-cc-sync \
  --project "$PROJECT" --region "$REGION" --image "$IMAGE" \
  --network "$VPC" --subnet "$SUBNET" --vpc-egress private-ranges-only \
  --cpu 2 --memory 4Gi --max-retries 1 --task-timeout 30m \
  --set-env-vars OPENPROJECT_HOST__NAME=${OPENPROJECT_HOST:?},OPENPROJECT_HTTPS=true,HERFY_CC_ISSUER=https://controlcenter.herfy.com,HERFY_CC_CLIENT_ID=${HERFY_CC_CLIENT_ID:?} \
  --set-secrets DATABASE_URL=op-database-url:latest,SECRET_KEY_BASE=op-secret-key-base:latest,HERFY_CC_CLIENT_SECRET=op-cc-client-secret:latest \
  --command bundle --args exec,rake,herfy:control_center:sync

gcloud scheduler jobs create http openproject-cc-sync \
  --project "$PROJECT" --location "$REGION" --schedule '0 3 * * *' --time-zone 'Asia/Kolkata' \
  --uri "https://run.googleapis.com/v2/projects/$PROJECT/locations/$REGION/jobs/openproject-cc-sync:run" \
  --http-method POST --oauth-service-account-email "$SERVICE_ACCOUNT"
