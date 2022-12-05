---
title: OpenProject 10.2.0
sidebar_navigation:
    title: 10.2.0
release_version: 10.2.0
release_date: 2019-11-11
---


# OpenProject 10.2.0

We released [OpenProject 10.2.0](https://community.openproject.com/versions/1390).
The release contains several bug fixes and we recommend updating to the newest version.

#### Bug fixes and changes

- Fixed: Many mails are still being sent synchronously, slowing down the application [[#28287](https://community.openproject.com/wp/28287)]
- Fixed: Work package webhooks not triggered when Setting.notified_events disabled [[#29501](https://community.openproject.com/wp/29501)]
- Fixed: EE teaser in project filter and work package filter look different [[#31424](https://community.openproject.com/wp/31424)]
- Fixed: Success messages displaced [[#31538](https://community.openproject.com/wp/31538)]
- Fixed: Estimated time not properly aligned [[#31540](https://community.openproject.com/wp/31540)]
- Fixed: Wrong formatting of preview cards [[#31572](https://community.openproject.com/wp/31572)]
- Fixed: Configure icon to change embedded tables have no impact [[#31574](https://community.openproject.com/wp/31574)]
- Fixed: Enabling sums for a custom field break work packages widget on project overview page [[#31576](https://community.openproject.com/wp/31576)]
- Fixed: Attachment filename not stringified [[#31580](https://community.openproject.com/wp/31580)]
- Fixed: SMTP_PASSWORD not correctly output in YAML configuration [[#31583](https://community.openproject.com/wp/31583)]
- Fixed: Change date of milestones in Gantt chart not possible [[#31596](https://community.openproject.com/wp/31596)]
- Fixed: System user is not active [[#31609](https://community.openproject.com/wp/31609)]
- Fixed: i18 // German: Delete in context menu should be "Löschen" and not "Lösche" [[#31636](https://community.openproject.com/wp/31636)]
- Changed: Upgrade CKEditor to 15.0 [[#31542](https://community.openproject.com/wp/31542)]
- Changed: Zen mode for project overview page [[#31559](https://community.openproject.com/wp/31559)]

#### Contributions

 

Thanks to Thanh Nguyen Nguyen from [Fortinet's FortiGuard Labs](https://fortiguard.com/) for identifying and responsibly disclosing the attachment filename stringification issue [#31580](https://community.openproject.com/wp/31580).
