# Herfy OpenProject on Cloud Run

`Dockerfile` layers the Control Center login (`lib/herfy`, rake task, initializer, OIDC engine
patch) onto the stock `openproject/openproject:<tag>` image. `cloudbuild.yaml` builds, pushes
and deploys it. Verified locally: the image boots, provisions the provider from env and
`/auth/herfy-control-center` redirects to Control Center.

Pin `_OPENPROJECT_TAG` to the exact version the database was created with (e.g. `17.0.2`).

## OIDC login needs Enterprise features
OpenProject gates SSO behind an Enterprise token. The image ships the fork's
`zz_enterprise_unlocked.rb` by default (`ENTERPRISE_UNLOCK=true`). If you hold a license token,
set `_ENTERPRISE_UNLOCK=false`.

## Cloud Run requirements (OpenProject is not a stateless web app)
* **Database:** external Postgres (Cloud SQL) via `DATABASE_URL`. Without it the image starts a
  throwaway Postgres inside the container.
* **Background worker:** the all-in-one image runs web + worker + cron in one container, so use
  `--no-cpu-throttling --min-instances=1 --max-instances=1` (jobs and the Control Center sync
  must keep running between requests).
* **Attachments:** mount a GCS bucket at `/var/openproject/assets` (Cloud Run volume mount).
* **Port 80**, at least 2 CPU / 4 GiB.

## First-time service
```
gcloud run deploy openproject --region us-central1 \
  --image us-central1-docker.pkg.dev/herfy-production/cloud-run-source-deploy/openproject:<sha> \
  --port 80 --cpu 2 --memory 4Gi --no-cpu-throttling --min-instances 1 --max-instances 1 \
  --add-cloudsql-instances <project:region:instance> \
  --add-volume name=assets,type=cloud-storage,bucket=<bucket> \
  --add-volume-mount volume=assets,mount-path=/var/openproject/assets \
  --set-env-vars OPENPROJECT_HOST__NAME=<openproject-host>,OPENPROJECT_HTTPS=true,HERFY_CC_ISSUER=https://controlcenter.herfy.com,HERFY_CC_CLIENT_ID=<app id> \
  --set-secrets DATABASE_URL=op-database-url:latest,SECRET_KEY_BASE=op-secret-key-base:latest,HERFY_CC_CLIENT_SECRET=op-cc-client-secret:latest
```
The Control Center app must have redirect URI
`https://<openproject-host>/auth/herfy-control-center/callback`, `oidc_client=true`, and access
to `GET /api/users/export` for the scheduled sync (run `rake herfy:control_center:sync` daily,
e.g. a Cloud Scheduler job that runs a Cloud Run job from the same image).
