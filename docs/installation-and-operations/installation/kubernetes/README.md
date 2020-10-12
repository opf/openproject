---
sidebar_navigation: false
---

# Kubernetes

Kubernetes is a container orchestration tool. As such it can use the
OpenProject docker container in the same manner as shown in the [docker section](../docker/#recommended-usage).

You can translate OpenProject's [`docker-compose.yml`](https://github.com/opf/openproject/blob/stable/10/docker-compose.yml)
for use in Kubernetes using [Kompose](https://github.com/kubernetes/kompose)
as described in the Kubernetes [documentation](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/).
