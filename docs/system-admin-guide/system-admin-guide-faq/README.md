---
sidebar_navigation:
  title: System admin FAQ
  priority: 001
description: Frequently asked questions regarding system administration
keywords: system admin FAQ, global admin, administration, system settings
---

# Frequently asked questions (FAQ) for system administration

## How do I know if I have system admin permissions?

If you can choose *Administration* when clicking on your avatar you have system admin permissions.

## How can I use the Slack plugin?

The slack plugin is deactivated per default in the Enterprise cloud. Please contact support to have it activated. For the Enterprise on-premises edition please have a look at [this instruction](../../system-admin-guide/integrations/#slack).

## Can I use a self-developed plugin in my Enterprise cloud?

No, that's not possible, as all tenants (customers) use the same code on the shard. But you can do this in Enterprise on-premises.

## How can I access the log files or increase the log level?

Please have a look at [these instructions](../../installation-and-operations/operation/monitoring).

## I'm seeing HTTP timeouts (408 Request Timeout) upon uploading larger files

The OpenProject installations do not configure a default timeout for the outer Apache2 web server. Please increase the Apache `Timeout` directive. Please see the Apache web server documentation for more information: [https://httpd.apache.org/docs/2.4/mod/core.html#timeout](https://httpd.apache.org/docs/2.4/mod/core.html#timeout)

## Further information

More FAQ can be found in the respective sections of this System admin guide.
