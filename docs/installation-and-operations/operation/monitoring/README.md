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

## Prometheus metrics

OpenProject can give metrics suitable to use with Prometheus.

To enable this option the [environment variable](../../configuration/environment/#environment-variables) `OPENPROJECT_PROMETHEUS_EXPORT` has to be set to `true`.
[Yabeda Prometheus gem](https://github.com/yabeda-rb/yabeda-prometheus-mmap) is used with [ActiveRecord](https://github.com/yabeda-rb/yabeda-activerecord/), [Rails](https://github.com/yabeda-rb/yabeda-rails/) and [Puma](https://github.com/yabeda-rb/yabeda-puma-plugin/) plugins.

Listening address is configured via `PROMETHEUS_EXPORTER_BIND` env variable with default 0.0.0.0. Port is configured by `PROMETHEUS_EXPORTER_PORT` variable with default 9394. Both provided by Prometheus gem.

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

## Logging concept

This section describes how OpenProject supports common security logging requirements such as those defined by the BSI IT-Grundschutz module OPS.1.1.5 (A1 & A3), which require a range of security-relevant events to be logged in accordance with a logging concept.

OpenProject covers **application-level logging**, including request logs, authentication-related events, application errors and security-relevant application behavior. Whether an event is logged depends on the configured [log level](#raising-the-log-level), which defaults to `info` and includes these events by default.

OpenProject **does not** itself cover operating system, network, host, file-integrity or infrastructure audit events. Regardless of how OpenProject is deployed (packaged installation, Docker Compose, all-in-one Docker image, Kubernetes/Helm or Terraform), logging responsibility is distributed across several layers:

- **OpenProject application logs**: request logs, authentication events, application errors and security-relevant application behavior.
- **Deployment platform logs**: events from the platform running OpenProject, for example systemd/`journalctl` on packaged installs, container logs on Docker/Compose, or workload lifecycle, secrets/configuration changes and RBAC on Kubernetes.
- **Infrastructure / provider logs**: operated by the platform operator or infrastructure provider (OS, container runtime, storage, network, host-level), including resources managed through infrastructure-as-code such as Terraform.

Application logs are available through the standard logging sinks described above (`journalctl`, `docker logs`, STDOUT) and can be forwarded to a central logging system or through OpenTelemetry integrations.

### Coverage of security logging requirements

The following table maps common security logging requirements to the layer that covers them and OpenProject's scope for each.

| Logging requirement | Covered by | Coverage |
| ------------------- | ---------- | -------- |
| Creation/modification of OpenProject users, groups and permissions | OpenProject | **Covered by application logging** for events in OpenProject. Available through the standard logging sinks, or through OpenTelemetry integrations. |
| Platform users, service accounts, roles and permissions | Deployment platform | Responsibility of the platform operator or infrastructure provider (e.g. Kubernetes RBAC and service accounts). |
| Changes to access credentials | OpenProject, Deployment platform, IdP | **Covered by application logging** for events in OpenProject. Secret and configuration changes at the platform level can be covered by the platform's audit logs (e.g. Kubernetes audit logs). |
| Successful/failed logins and logouts | OpenProject, IdP | **Covered by application logging** for all internal login requests. Externally delegated requests (e.g. OIDC) are expected to be logged by the identity provider and do not reach the application server. |
| Access to system, program and file resources | Infrastructure provider / operator | Not covered by OpenProject application logs. Requires OS, container runtime, storage or host-level logging. |
| System starts, restarts and shutdowns | Deployment platform, Infrastructure provider | Not covered by OpenProject application logs. Requires OS, container runtime, storage or host-level logging. |
| Execution of applications, programs and scripts | OpenProject, Deployment platform, Infrastructure provider | **Covered for OpenProject executions** through application logging. The deployment platform covers workload, container and scheduled job starts. Detailed process execution inside containers requires additional runtime/host security tooling. |
| Installations and uninstallations | Deployment platform, Infrastructure provider | Covered by the platform through deployment, image and resource changes (e.g. Helm, GitOps or Terraform). OS package-level installation logs are outside OpenProject. |
| Configuration and system changes | Deployment platform, Infrastructure provider | Covered by the platform through its managed resources (e.g. Kubernetes API or Terraform state). Infrastructure changes are covered by infrastructure/cloud provider or operator logs where applicable. |
| Process information | Deployment platform, Infrastructure provider | Partially covered by platform workload lifecycle events. Detailed process start/termination inside containers requires runtime or host monitoring. |
| System/file integrity | Infrastructure provider / operator | Not covered by OpenProject. Requires host, container runtime, file-integrity monitoring or EDR/XDR tooling. |
| Program and system crashes | OpenProject, Deployment platform | Covered by OpenProject application logs for web and background processes. The deployment platform covers container/process status, restart and failure events. |
| Network boundary communication | Deployment platform, Infrastructure provider | Not covered by OpenProject itself. Covered by ingress, proxy, firewall, service mesh, network policy, cloud or infrastructure logging where implemented. |
| Communication within networks and between IT systems | Deployment platform, Infrastructure provider | Partially covered by network infrastructure, service mesh, ingress/proxy and monitoring/logging tools where implemented. |
| Network infrastructure security events | Deployment platform, Infrastructure provider | Outside OpenProject application scope. Covered by the platform operator, network layer or infrastructure provider. |

### References

- Every request is logged with the acting user, HTTP method, route and performed action. See [Logging information](#logging-information) above and the [`ApplicationController` request logging](https://github.com/opf/openproject/blob/v17.6.0/app/controllers/application_controller.rb#L207-L215).
- All request logs, including status, routes and performed action, are part of the Ruby on Rails framework standards.
