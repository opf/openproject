---
sidebar_navigation:
  title: Scaling
  priority: 5

---

# Scaling your OpenProject installation

The following environment variables are relevant for performance.

- `OPENPROJECT_WEB_WORKERS`: Number of web workers handling HTTP requests. Note that in Kubernetes deployments, this value is applied using replicas of the services.
- `OPENPROJECT_WEB_TIMEOUT`: Maximum request processing time in seconds.
- `OPENPROJECT_WEB_WAIT__TIMEOUT`: Timeout for waiting requests in seconds.
- `OPENPROJECT_WEB_MIN__THREADS`: Minimum number of threads per web worker (default: 3).
- `OPENPROJECT_WEB_MAX__THREADS`: Maximum number of threads per web worker (default: 5).

> [!NOTE]
>
> Due to Ruby's Global VM Lock (GVL), MRI Ruby can only execute one thread at a time for CPU-bound work. More threads increase memory usage and context-switching overhead without proportional throughput gains. The defaults of 3–5 threads per worker reflect this constraint. See the [Rails performance guide](https://guides.rubyonrails.org/tuning_performance_for_deployment.html#understanding-ruby-s-concurrency-and-parallelism) for a detailed explanation. Scale horizontally by adding more workers rather than increasing thread counts.
- `OPENPROJECT_GOOD__JOB__MAX_THREADS`: Maximum number of threads for background workers.

## Packaged installation

Note: Depending on your free RAM on your system, we recommend you raise the default number of web processes. The default from 9.0.3 onwards is 4 web processes. Each worker will take roughly 300-400MB RAM.

We recommend at least 4 web processes. Please check your current web processes count with:

```shell
sudo openproject config:get OPENPROJECT_WEB_WORKERS
```

If it returns nothing, the default process count of `4` applies. To increase or decrease the process count, call

```shell
sudo openproject config:set OPENPROJECT_WEB_WORKERS=number
```

Where `number` is a positive number between 1 and `round(AVAILABLE_RAM * 1.5)`.

After changing these values, simply restart the web process:

```shell
sudo openproject restart web
```

### Scaling the number of background workers

Note: Depending on your free RAM on your system, we recommend you raise the default number of background processes. By default, one background worker is spawned. Background workers are responsible for delivering mails, copying projects, performing backups and deleting resources.

We recommend to have two background worker processes. Please check your current web processes count with:

To set the desired process count, call

```shell
sudo openproject scale worker=number
```

Where `number` is a positive number between 1 and `round(AVAILABLE_RAM * 1.5)`.

The respective systemd services are automatically created or removed. If you were already at the entered value, it will output `Nothing to do.`

## All-in-one Docker-based installation

There is no way to scale the all-in-one docker installation. We recommend to use a docker compose or Kubernetes deployment to provide full flexibility in scaling your installation.

## docker-compose based installation

To scale your docker compose installation, update your `.env` and upgrade the worker definitions from above. For example:

```shell
OPENPROJECT_WEB_WORKERS=number
```

Where `number` is a positive number between 1 and `round(AVAILABLE_RAM * 1.5)`.

> [!NOTE]
>
> Docker compose is not horizontally scalable on multiple instances without additional tools

## Kubernetes and Helm-Charts

To scale your OpenProject Helm chart / kubernetes deployment, you need to adjust the values in your values.yaml file, specifically:

- **Increase replicaCount**: This controls the number of OpenProject web instances.
- **Increase backgroundReplicaCount**: This controls the number of background worker instances.
- **Adjust worker replicas**: In the workers section, increase replicas for different types of workers.
- **Ensure adequate resource allocation**: Scale up CPU and memory limits accordingly.

For example:

```yaml
 # Web deployment containers replicas
replicaCount: 2

# Web deployment resources
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "4Gi"
    cpu: "4"

# Worker deployment
workers:
  default:
    replicas: 1  # Keep 1 worker
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "4Gi"
        cpu: "4"
```
