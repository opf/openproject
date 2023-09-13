---
sidebar_navigation:
  title: Environments
description: Get an overview of the different environemnts at play in the development phases of OpenProject
keywords: environments, CI, development
---



# OpenProject Environments

OpenProject is continuously tested and developed using the following environments

| **Environment**                 | **Description**                                              | **Release Target**                                           | **Deployment cycles**                                        |
| ------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Edge                            | automatic deployments through [GitHub actions](https://github.com/opf/openproject/blob/dev/.github/workflows/continuous-delivery.yml) for instances on openproject-edge.com<br />Subject for continuous QA, acceptance and regression testing. | Next minor or major release planned and developed in our [community instance](https://community.openproject.org/projects/openproject/) | On every push to `opf/openproject#dev`                       |
| Stage                           | automatic deployments through [GitHub actions](https://github.com/opf/openproject/blob/dev/.github/workflows/continuous-delivery.yml) for instances on openproject-stage.com.<br />Subject for QA and acceptance testing of bugfix prior to stable relases. | Next patch release of the current stable release following our [release plan](https://community.openproject.org/projects/openproject/work_packages?query_id=918) | On every push to `release/X.Y`, where `X.Y.` is the current stable release major and minor versions. |
| Production<br />(SaaS / Cloud)  | Production cloud environments. Deployed manually with the latest stable release | Stable releases                                              | Manually                                                     |
| Production<br />(Docker images) | [Official public OpenProject docker images](https://hub.docker.com/r/openproject/community)<br />Continuous delivery for development versions using `dev-*`tags.<br />Stable releases through major, minor, or patch level tags. | development (`dev`, `dev-slim` tag)<br />Stable releases (`X`, `X.Y`, `X.Y.Z`, `X-slim`, `X.Y-slim`, `X.Y.Z-slim`) | Automatically on new releases of the OpenProject application |
| Production<br />(Packages)      | [Official public OpenProject Linux packages](https://www.openproject.org/docs/installation-and-operations/installation/packaged/) <br /><br />Stable releases for supported distributions | Stable releases                                              | Automatically on new releases of the OpenProject application |
| PullPreview                     | Temporary instances for development of features scope to a pull request. | Feature branches                                             | Automatically deployed when developers/QA request a pull preview instance by labelling pull requests with the `PullPreview` tag. |



