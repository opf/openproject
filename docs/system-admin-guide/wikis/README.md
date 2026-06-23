---
sidebar_navigation:
  title: Wikis
  priority: 835
description: File storages in OpenProject.
keywords: wikis, xwiki, wiki integration, wiki provider, internal wiki
---

# Wikis

Under *Administration → Wikis* you can manage the application wide available wikis. Generally, there is a distinction
between internal and external wikis. The application provides the possibility to configure wiki providers, which are
considered to have multiple wikis inside. Wikis are globally available in the application.

## Internal wiki

Under *Administration → Wikis → Internal wiki* you can enable or disable the internal wiki provider. If the wiki
provider is enabled, each project can have its own wiki. Access level is defined by the member's role in the project.

> *Insert screenshot of internal wiki configuration*

## External wikis

Under [Wiki providers](./wiki-providers) you can configure external wiki providers. External providers outsource the
user permission to the external server, thus it is required to connect the OpenProject user to a user on the external
provider's instance.
