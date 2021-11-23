---
sidebar_navigation: false
---

# Kubernetes

Kubernetes is a container orchestration tool. As such it can use the
OpenProject docker container in the same manner as shown in the [docker section](../docker/#one-container-per-process-recommended).

You can translate OpenProject's [`docker-compose.yml`](https://github.com/opf/openproject/blob/stable/12/docker-compose.yml)
for use in Kubernetes using [Kompose](https://github.com/kubernetes/kompose)
as described in the Kubernetes [documentation](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/).

_Note: Make sure you are using kompose version **1.19** or newer for this to work._
