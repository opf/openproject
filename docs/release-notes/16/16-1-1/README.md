---
title: OpenProject 16.1.1
sidebar_navigation:
    title: 16.1.1
release_version: 16.1.1
release_date: 2025-06-26
---

# OpenProject 16.1.1

Release date: 2025-06-26

We released OpenProject [OpenProject 16.1.1](https://community.openproject.org/versions/2206).
The release contains several bug fixes and we recommend updating to the newest version.
In these Release Notes, we will give an overview of important feature changes.
At the end, you will find a complete list of all changes and bug fixes.

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: ActiveRecord::Deadlocked on Attachments::FinishDirectUploadJob#perform leading to lost uploads \[[#63380](https://community.openproject.org/wp/63380)\]
- Bugfix: Unclear error message on bulk edit of parent and children wps \[[#64203](https://community.openproject.org/wp/64203)\]
- Bugfix: Wrong wording for project phases in system administration \[[#64794](https://community.openproject.org/wp/64794)\]
- Bugfix: Edited reminder is not working (not reminding at the selected time and date) \[[#64971](https://community.openproject.org/wp/64971)\]
- Bugfix: Error 500 when making a predecessor with children a child of its successor \[[#64973](https://community.openproject.org/wp/64973)\]
- Bugfix: Rendering and Server Error when managing a Custom Action with a multi-select user custom field. \[[#64981](https://community.openproject.org/wp/64981)\]
- Bugfix: ActiveRecord::RecordNotUnique (app/services/journals/create\_service.rb:99 in block in Journals::CreateService#create\_journal) \[[#65009](https://community.openproject.org/wp/65009)\]
- Bugfix: SystemStackError in WorkPackage::SchedulingRules#schedule\_automatically? \[[#65062](https://community.openproject.org/wp/65062)\]
- Bugfix: OIDC does not forward to end\_session\_endpoint as configured \[[#65076](https://community.openproject.org/wp/65076)\]
- Bugfix: Inline comment attachments are not linked to the comment when submit is via API \[[#65077](https://community.openproject.org/wp/65077)\]
- Bugfix: create\_meeting\_minutes was never renamed to manage\_outcomes \[[#65081](https://community.openproject.org/wp/65081)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
