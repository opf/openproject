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
Edit the placeholders in `service.yaml`, then:
```
gcloud run services replace docker/herfy/service.yaml --region us-central1
```
`service.yaml` already carries the settings below. Afterwards `cloudbuild.yaml` only swaps the image.

* **Database URL:** use TCP over the instance's **private IP**
  (`postgres://user:pass@10.x.x.x:5432/openproject`) with Direct VPC egress (`network-interfaces`
  annotation). Do not use the Cloud SQL socket form (`?host=/cloudsql/...`): the image's
  `docker/prod/seeder` strips everything after `?` from `DATABASE_URL`.
* **Slow first boot:** migrations and seeding run at startup, so the startup probe allows up to
  10 minutes (`failureThreshold: 60` x 10s) and startup CPU boost is on.
* **GCS volume:** the app runs as uid/gid 1000, so the mount sets `uid=1000,gid=1000` and file/dir
  modes. FUSE is slow for heavy attachment traffic.
* **Secrets:** create `op-database-url`, `op-secret-key-base`, `op-cc-client-secret` in Secret
  Manager and grant the runtime service account `roles/secretmanager.secretAccessor`.
* **Cloud Build:** its service account needs `roles/run.admin`, `roles/iam.serviceAccountUser`
  on the runtime account, and `roles/artifactregistry.writer`.

## Daily Control Center sync
`sync-job.sh` creates a Cloud Run job (same image, runs `rake herfy:control_center:sync`) and a
Cloud Scheduler trigger at 03:00 IST. The scheduler service account needs `roles/run.invoker`
on the job.

The Control Center app must have redirect URI
`https://<openproject-host>/auth/herfy-control-center/callback`, `oidc_client=true`, and access
to `GET /api/users/export` for the scheduled sync.
