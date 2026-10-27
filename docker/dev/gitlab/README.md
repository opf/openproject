## First-time setup

First check whether you need any of the changes present in `docker-compose.override.example.yml`:

* self-signed SSL certificates to be shared with GitLab
* forwarding traffic to the host (if not running OpenProject via docker compose)

If you need any of those, copy `docker-compose.override.example.yml` to `docker-compose.override.yml` and uncomment relevant
lines.

You can then start GitLab through `docker compose up`. Afterwards you can find the root password using

    docker compose exec -it gitlab cat /etc/gitlab/initial_root_password

The username is **root**.

## Starting GitLab

Starting GitLab works through

    docker compose up

You'll have to wait some time before GitLab becomes reachable via your browser. In the meantime you might still see a 404 error
from the shared front proxy.

## Configuring webhooks

GitLab by default does not allow certain kinds of webhooks to target the local network, however that's usually required for
local testing of webhooks. To enable them go to

    https://<your-gitlab-hostname>/admin/application_settings/network#js-outbound-settings

Ensure that both relevant options are **enabled**:

* Allow requests to the local network from webhooks and integrations
* Allow requests to the local network from system hooks
