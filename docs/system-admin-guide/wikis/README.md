---
sidebar_navigation:
  title: Wikis
  priority: 835
description: Wiki providers in OpenProject.
keywords: wikis, xwiki, wiki integration, wiki provider, internal wiki
---

# Wikis

Under *Administration → Wikis* you can manage the application wide available wikis. Generally, there is a distinction
between internal and external wikis. The application provides the possibility to configure wiki providers, which are
considered to contain multiple wikis. Wikis are globally available in the application.

## Internal wiki

Under *Administration → Wikis → Internal wiki* you can enable or disable the internal wiki provider. If the wiki
provider is enabled, each project can have its own wiki. If disabled, no project will be able to have a wiki. Projects,
which already had a wiki when the internal provider gets disabled, will lose access to their wiki as long as the
internal provider is disabled. Permissions for the project's wiki are set by the member's role in the project.

![OpenProject administration showing internal wiki settings](openproject_system_admin_wikis_internal_wiki.png)

## External wikis

Under [Wiki providers](./wiki-providers) you can configure external wiki providers. External wiki providers manage their
own user permissions, thus it is required to connect the OpenProject user to a user on the external provider's instance.
