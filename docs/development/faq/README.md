---
sidebar_navigation:
  title: OpenProject FAQ
  priority: 999
description: Frequently asked questions for development
robots: index, follow
keywords: FAQ, change code, developing, plug-in
---
# Frequently asked questions (FAQ) for development

## Is there an ER diagram (entity relationship diagram) for OpenProject?

No. The database layout is subject to continuous change. Every upgrade, even from one patch level release to the next, might change the database layout. Because of that, it is also not advisable to integrate on the database level (e.g. for data warehousing/dashboards).

## Is there documentation for creating my own plugin?

The documentation for creating plugins is indeed limited at the moment. What we have is this mostly [this one](../create-openproject-plugin) and the [proto plugin](https://github.com/opf/openproject-proto_plugin).

## Additional information

For additional information and FAQ have a look at the other FAQ section, e.g. [in the Installation and upgrade guide](../../installation-and-operations/faq).

