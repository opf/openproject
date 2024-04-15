---
sidebar_navigation:
  title: BIM edition
  priority: 100
---

# OpenProject BIM edition

## Installing OpenProject BIM edition

For installing the OpenProject BIM edition please follow the general [system requirements](../system-requirements/) and [installation guidelines](../installation/packaged/).
Under [Step 1](../installation/packaged/#step-1-select-your-openproject-edition) please select OpenProject BIM.

## Changing to OpenProject BIM edition

An existing OpenProject on-premises (self hosted) installation can easily be switched to the BIM Edition. The BIM Edition extends the capabilities of a normal OpenProject installation with special features for the construction industry.

Switching to the BIM Edition will not affect your existing data. Your team will be able to continue working just as before. By switching to the BIM edition additional features will become available  when you activate the "BCF" module in the [project's settings](../../user-guide/projects/project-settings/modules).

### Backup and upgrade

First, backup your data and update your installation to the latest OpenProject version as described in [Upgrading](../operation/upgrading).
Make sure that you not only install the new package but also run `sudo openproject configure` as described before proceeding.

### Switching to BIM Edition

Now that your OpenProject instance is up to date, you can _reconfigure_ it to be a BIM Edition.

On the command line of your server run the following command. It will open a wizard that
guides you through through the most important installation settings of your instance.
On the first screen it will ask you to select the edition. Please select _bim_ and click _next_.
You can keep the screens that follow just as they are. You don't need to change any setting.
Your current settings will be preselected for you. You can simply click "next" in every step
until the end of the wizard. Finally, this will also
trigger the installation of the necessary libraries and tools for 3D model conversion.

`sudo openproject reconfigure`

Congratulations, you've successfully switched to the BIM Edition. However, for the best
experience you might consider also the next configuration.

You can check that all tools for the IFC model conversion were installed by going to
_-> Administration -> Information_ and check that _IFC conversion pipeline available_
has a check icon (✓) to the right.

### Activating the BCF module per default for every new project (optional)

You can enable the BCF module per default for all new projects in the future.

Go to _-> Administration -> System settings -> Projects_ and within the section
_Settings for new projects_ activate the checkbox for _BCF_.

### Add typical work package types and statuses for BCF management (optional)

For BCF management process you might want to add special work package types to your
installation.

In freshly created OpenProject BIM instances those types are already present. However,
as you have just switched from a normal OpenProject installation you will need to create
those work package types by hand. Please find detailed instructions on how to add work
package types in [Manage Work Package Types](../../system-admin-guide/manage-work-packages/work-package-types/).

You might consider adding the following typical work package types:

- Issue (color `indigo-7`)
- Clash (color `red-8`)
- Remark (color `GREEN (DARK)`)
- Request (color `cyan-7`)

We recommend that each type has the following status options:

- New (color `blue-6`)
- In progress (color `orange-6`)
- Resolved (color `'green-3`)
- Closed (color `'gray-3`)

### Activating the "OpenProject BIM" theme (optional)

OpenProject installations with a valid Enterprise on-premises edition token can switch to the BIM
theme.

Go to _-> Administration -> Design_ and from the _Themes_ drop down menu choose _OpenProject BIM_.

## Docker installation OpenProject BIM

### OpenProject BIM edition with Docker Compose

In order to use BIM edition inside a [docker-compose OpenProject installation](../installation/docker/), in the `docker-compose.override.yml` file in `x-op-app` > `environment` add one line

```yaml
    OPENPROJECT_EDITION: "bim"
```

This could look like this after editing file:

```yaml
x-op-app: &app
  <<: *image
  <<: *restart_policy
  environment:
    OPENPROJECT_CACHE__MEMCACHE__SERVER: "cache:11211"
    OPENPROJECT_EDITION: "bim"
    OPENPROJECT_RAILS__CACHE__STORE: "memcache"
    OPENPROJECT_RAILS__RELATIVE__URL__ROOT: "${OPENPROJECT_RAILS__RELATIVE__URL__ROOT:-}"
    DATABASE_URL: "postgres://postgres:p4ssw0rd@db/openproject"
    USE_PUMA: "true"
    # set to true to enable the email receiving feature. See ./docker/cron for more options
    IMAP_ENABLED: "${IMAP_ENABLED:-false}"
```

Note: If the current Docker installation does not yet hold important information it is recommended to simply create all docker containers from scratch as the seeded data such as themes, types, and demo projects are different in the BIM edition. The demo data gets seeded only at the very first time run of the container. The Docker volumes are required to be removed e.g. by issuing `docker-compose down --volumes`
