---
sidebar_navigation:
  title: Monitoring & Logs
  priority: 6
---

# Monitoring your OpenProject installation

OpenProject provides different means of monitoring and auditing your application.

## Logging information

In production, OpenProject uses [Lograge formatter](https://github.com/roidrage/lograge) `key_value` logger by default. Every request will result in the following `info` log level:

```text
I, [2023-11-14T09:21:15.136914 #56791]  INFO -- : [87a5dceb-0560-4e17-8577-2822106dfc00] method=GET path=/ format=html controller=HomescreenController action=index status=200 allocations=133182 duration=237.82 view=107.45 db=116.50 user=85742
```

This formatter makes it easy to parse and analyze logs. Let's take a look at the values:

| Log entry                                      | Description                                                  |
| ---------------------------------------------- | ------------------------------------------------------------ |
| `I`                                            | First letter of the level (Debug, Info, Warn, Error, ...)    |
| `[2023-11-14T09:21:15.136914 #56791]`          | ISO8601 timestamp and #Puma worker PID                       |
| `INFO`                                         | Log level                                                    |
| `[87a5dceb-0560-4e17-8577-2822106dfc00]`       | Request ID [Unique ID in the request](https://api.rubyonrails.org/classes/ActionDispatch/RequestId.html) added by Rails used to connect other log entries to that request. |
| `method=GET`                                   | HTTP method                                                  |
| `path=/`                                       | Requested path                                               |
| `format=html`                                  | Mime type                                                    |
| `controller=HomescreenController action=index` | Rails controller and used action method responding to the request, information for debugging |
| `status=200`                                   | HTTP response code                                           |
| `allocations=1333182`                          | Rails allocated memory objects instrumentation               |
| `duration=237.82`                              | Complete response duration (in ms)                           |
| `view=107.45`                                  | Time spent in view (in ms)                                   |
| `db=116.50`                                    | Time spent in database (in ms)                               |
| `user=85742`                                   | User ID of the instance                                      |

## Displaying and filtering log files

### Packaged installation

In a package-based installation, the `openproject` command line tool can be
used to see the log information. The most typically use case is to show/follow
all current log entries. This can be accomplished using the the `–tail` flag.
See example below:

```shell
sudo openproject logs --tail
```

You can abort this using Ctrl + C.

**systemd / journalctl**

On most distributions, OpenProject does not maintain its own log files, but sends logs directly to `journalctl`. On older distributions that use either sysvinit or upstart, all the logs are stored in `/var/log/openproject/`.

You can get all logs of the web processes like this:

```shell
journalctl -u openproject-web-1
```

Likewise, to get all logs of the background worker processes:

```shell
journalctl -u openproject-worker-1
```

journalctl has flexible filtering options to search for logs. For example, add `--since "1 hour ago"` to show logs printed in the past hour.

### Docker-compose

In a docker-based installation, all logs are redirected to STDOUT so you can use the normal docker tools to manage your logs.

For instance for the Compose-based installation:

```shell
docker-compose logs -f --tail 1000
```

### All-in-one / Slim docker container

```shell
docker logs -f --tail 1000 openproject
```

## Raising the log level

OpenProject can log at different service levels, the default being `info`. You can set the [environment variable](../../configuration/environment/#environment-variables) `OPENPROJECT_LOG__LEVEL` to any of the following values:

- `debug`: All activity, resulting in the highest amount of logging
- `info`: Common activities such as user logins (when enabled) and information about requests, including warnings and errors
- `warn`: Operational warnings that might need resolution as well as error messages
- `error` Caught or uncaught application errors, as well as fatal errors.

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
- `https://your-hostname.example.tld/health_checks/mail` - SMTP configuration check.
- `https://your-hostname.example.tld/health_checks/puma` - A check on Puma web server.
- `https://your-hostname.example.tld/health_checks/worker` - A check to ensure background jobs are being processed.
- `https://your-hostname.example.tld/health_checks/worker_backed_up` - A check to determine whether background workers are at capacity and might need to be scaled up to provide timely processing of mails and other background work.
- `https://your-hostname.example.tld/health_checks/all` - All of the above checks and additional checks combined as one. Not recommended as the liveliness check of a pod/container.

### Optional authentication

You can optionally provide a setting `health_checks_authentication_password` (`OPENPROJECT_HEALTH__CHECKS__AUTHENTICATION__PASSWORD`) that will add a basic auth challenge to the `/health_checks` endpoint. Please be aware that this might break existing container health services in place in the docker-compose and k8s based deployments, so use with care or prefer to use a network based separation instead on your proxy level.
