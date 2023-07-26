---
sidebar_navigation:
  title: Helm Chart
  priority: 280
---

# Helm Chart

## Basic commands

```bash
helm repo add openproject https://charts.openproject.org
helm upgrade --create-namespace --namespace openproject --install my-openproject openproject/openproject
```

## Introduction

This chart bootstraps an OpenProject instance, optionally with a PostgreSQL database and Memcached.

## Prerequisites
- Kubernetes 1.16+
- Helm 3.0.0+
- PV provisioner support in the underlying infrastructure

## Installing the Chart

You can install the chart with the release name `my-openproject` in its own namespace like this:

```bash
helm upgrade --create-namespace --namespace openproject --install my-openproject openproject/openproject
```

The namespace is optional, but using it does make it easier to manage the resources
created for OpenProject.



## Configuration

Configuration of the chart takes place through defined values, and a catch-all entry `environment` to provide all possible variables through ENV that OpenProject supports. To get more information about the possible values, please see [our guide on environment variables](../../configuration/environment/).



### Available OpenProject specific helm values

We try to map the most common options to chart values directly for ease of use. The most common ones are listed here, feel free to extend available values [through a pull request](https://github.com/opf/helm-charts/).



**OpenProject image and version**

By default, the helm chart will target the latest stable major release. You can define a custom [supported docker tag](https://hub.docker.com/r/openproject/community/) using `image.tag`. Override container registry and repository using `image.registry` and `image.repository`, respectively.



**HTTPS mode**

Regardless of the TLS mode of ingress, OpenProject needs to be told whether it's expected to run and return HTTPS responses (or generate correct links in mails, background jobs, etc.). If you're not running https, then set `openproject.https=false`.



**Seed locale** (13.0+)

By default, demo data and global names for types, statuses, etc. will be in English. If you wish to set a custom locale, set `openproject.seed_locale=XX`, where XX can be a two-character ISO code. For currently supported values, see the `OPENPROJECT_AVAILABLE__LANGUAGES` default value in the [environment guide](../../configuration/environment/).



**Admin user** (13.0+)

By default, OpenProject generates an admin user with password `admin` which is required to change after first interactive login.
If you're operating an automated deployment with fresh databases for testing, this default approach might not be desirable.

You can customize the password as well as name, email, and whether a password change is enforced on first login with these variables:

```
openproject.admin_user.password="my-secure-password"
openproject.admin_user.password_reset="false"
openproject.admin_user.name="Firstname Lastname"
openproject.admin_user.mail="admin@example.com"
```



## Updating the configuration

The OpenProject configuration can be changed through environment variables.
You can use `helm upgrade` to set individual values.

For instance:

```
helm upgrade --reuse-values --namespace openproject my-openproject --set environment.OPENPROJECT_IMPRESSUM__LINK=https://www.openproject.org/legal/imprint/ --set environment.OPENPROJECT_APP__TITLE='My OpenProject'
```

Find out more about the [configuration](../../configuration/environment/) section.

## Uninstalling the Chart

To uninstall the release with the name my-openproject do the following:

```bash
helm uninstall --namespace openproject my-openproject
```

> **Note**: This will not remove the persistent volumes created while installing.
> The easiest way to ensure all PVCs are deleted as well is to delete the openproject namespace
> (`kubectl delete namespace openproject`). If you installed OpenProject into the default
> namespace, you can delete the volumes manually one by one.

## Troubleshooting

### Web deployment stuck in `CrashLoopBackoff`

Describing the pod may yield an error like the following:

```
65s)  kubelet            Error: failed to start container "openproject": Error response from daemon: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: error setting cgroup config for procHooks process: failed to write "400000": write /sys/fs/cgroup/cpu,cpuacct/kubepods/burstable/pod990fa25e-dbf0-4fb7-9b31-9d7106473813/openproject/cpu.cfs_quota_us: invalid argument: unknown
```

This can happen when using **minikube**. By default, it initialises the cluster with 2 CPUs only.

Either increase the cluster's resources to have at least 4 CPUs or install the OpenProject helm chart with a reduced CPU limit by adding the following option to the install command:

```
--set resources.limits.cpu=2
```

### Root access in OpenShift

The OpenProject container performs tasks as root during setup.
In [OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift) this is not allowed. You will have to [add](https://examples.openshift.pub/deploy/scc-anyuid/) the `anyuid` SCC (Security Context Constraint)
to OpenProject's service account.
