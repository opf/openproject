---
sidebar_navigation:
  title: LDAP development setup
  priority: 920
---

# Set up a development LDAP server

**Note:** This guide is targeted only at development with OpenProject. For the LDAP configuration guide, please see this [here](../../system-admin-guide/authentication/ldap-connections/)

OpenProject comes with a built-in LDAP server for development purposes. This server uses [ladle gem](https://github.com/NUBIC/ladle)
to run an underlying apacheDS server.

This guide will show you how to set it up in your development instance.

## Prerequisites

- A local java/JRE environment installed (openjdk, java installed via homebrew, etc.)
- A development setup of OpenProject (or any other configurable installation)

## Running the LDAP server

You only need to run this rake task to start the server:

```shell
./bin/rails ldap_groups:development:ldap_server
```

It will both output the different users and groups, as well as connection details. Starting this task will ensure
an LDAP connection is created or updated to make sure you can use it right away.
