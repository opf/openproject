---
sidebar_navigation: false
---

# Kubernetes

Kubernetes is a container orchestration tool. As such it can use the
OpenProject docker container in the same manner as shown in the [docker section](../docker/#one-container-per-process-recommended).

In the [openproject-deploy](https://github.com/opf/openproject-deploy/blob/stable/12/kubernetes/README.md) repository we provide further information and an exemplary set of YAML files defining a complete OpenProject setup on Kubernetes.

## Helm

Helm charts are also available but still under active development.
We do not recommend using them for production just yet.

You can find the current chart under https://github.com/opf/openproject-helm-chart.

In the future we will publish the chart in our opf repository.
Until then you will have to clone the repository above and follow the instructions in its README.
