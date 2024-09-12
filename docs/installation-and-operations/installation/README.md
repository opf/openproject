---
sidebar_navigation:
  title: Installation
  priority: 400
---

# Installing OpenProject

OpenProject can be setup in these different ways:

| Topic                                                | Content                                                                               |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------- |
| [Installation with DEB/RPM packages](./packaged)     | This is the recommended way to install OpenProject                                    |
| [Installation with Docker Compose](./docker-compose) | This allows to setup OpenProject in an isolated manner using Docker Compose           | 
| [Installation with single Docker container](./docker)| This allows to setup OpenProject in a single Docker container                         | 
| [Installation with Helm charts](./helm-chart)        | This allows to setup OpenProject using Helm charts                                    |
| [Other](misc/)                                       | Extra information on installing OpenProject on specific platforms such as Kubernetes. |

> **NOTE: We recommend using the DEB/RPM package installation.**

## Frequently asked questions (FAQ)

### Do you have a step-by-step guide to installing OpenProject Enterprise on-premises under Active Directory?

We have a guide on [how to use OpenProject with your Active Directory](../../system-admin-guide/authentication/ldap-connections/).
In addition, with the Enterprise on-premises edition it is also possible to [link LDAP groups with groups in OpenProject](../../system-admin-guide/authentication/ldap-connections/ldap-group-synchronization/).
