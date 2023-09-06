---
sidebar_navigation:
  title: Monitoring & Logs
  priority: 6
---

# Monitoring your OpenProject installation

## Show logs

In a package-based installation, the `openproject` command line tool can be
used to see the log information. The most typically use case is to show/follow
all current log entries. This can be accomplished using the the `–tail` flag.
See example below:

```shell
sudo openproject logs --tail
```

You can abort this using Ctrl + C.

Note:

* On distributions that are based on systemd, all the logs are sent to journald, so you can also display them via `journalctl`.
* On older distributions that use either sysvinit or upstart, all the logs are stored in `/var/log/openproject/`.
* If you need to share the logs you can save them in a file using `tee` like this: `sudo openproject logs --tail | tee openproject.log`

In a docker-based installation, all logs are redirected to STDOUT so you can use the normal docker tools to manage your logs.

For instance for the Compose-based installation:

```shell
docker-compose logs -f --tail 1000
```

Or the all-in-one docker installation:

```shell
docker logs -f --tail 1000 openproject
```

### Raising the log level

OpenProject can log at different service levels, the default being `info`. You can set the [environment variable](../../configuration/environment/#environment-variables) `OPENPROJECT_LOG__LEVEL` to any of the following values:

- debug, info, warn, error

For example, to set this in the packaged installation, use the following command:

```shell
openproject config:set OPENPROJECT_LOG__LEVEL="debug"
service openproject restart
```

For Docker-based installations, add the ENV variable to your env file and restart the containers.


## Health checks

OpenProject uses the [okcomputer gem](https://github.com/sportngin/okcomputer) to provide built-in health checks on database, web, and background workers.

We provide the following health checks: 

- `https://your-hostname.example.tld/health_checks/default` - An application level check to ensure the web workers are running.
- `https://your-hostname.example.tld/health_checks/database` - A database liveliness check.
- `https://your-hostname.example.tld/health_checks/delayed_jobs_never_ran` - A check to ensure background jobs are being processed.
- `https://your-hostname.example.tld/health_checks/delayed_jobs_backed_up` - A check to determine whether background workers are at capacity and might need to be scaled up to provide timely processing of mails and other background work.
- `https://your-hostname.example.tld/health_checks/all` - All of the above checks and additional checks combined as one. Not recommended as the liveliness check of a pod/container.

### Optional authentication

You can optionally provide a setting `health_checks_authentication_password` (`OPENPROJECT_HEALTH__CHECKS__AUTHENTICATION__PASSWORD`) that will add a basic auth challenge to the `/health_checks` endpoint. Please be aware that this might break existing container health services in place in the docker-compose and k8s based deployments, so use with care or prefer to use a network based separation instead on your proxy level.

