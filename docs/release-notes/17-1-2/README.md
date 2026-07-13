---
title: OpenProject 17.1.2
sidebar_navigation:
    title: 17.1.2
release_version: 17.1.2
release_date: 2026-02-26
---

# OpenProject 17.1.2

Release date: 2026-02-26

We released OpenProject [OpenProject 17.1.2](https://community.openproject.org/versions/2273).
The release contains several bug fixes and we recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.

<!-- BEGIN CVE AUTOMATED SECTION -->

## Security fixes

### CVE-2026-27715 - User mentions result in information disclosure of user names

The Work Package Activity comment feature does not properly validate whether a mentioned user is a member of the current project.

By manipulating the `data-id` attribute of the `<mention>` element in the comment request, a low-privileged user who has access to a single project can mention arbitrary users within the same organization, even if those users are not members of the project.

The backend accepts the supplied user ID without enforcing project membership checks, resolves the mention, and triggers server-side notification workflows (including email notifications).

This behavior violates the intended access control and project isolation model.

This vulnerability was reported by user slashx0x as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-j4m9-7hff-8qgr](https://github.com/opf/openproject/security/advisories/GHSA-j4m9-7hff-8qgr)

### CVE-2026-27716 - Information disclosure on OpenProject through /api/v3/custom_fields/{id}/items

The api implementation for `custom_fields` lacks any validation that the current user is authorized on any project using the custom\_field data. This leaks potentially sensitive, project specific business logic.

This vulnerability was reported by user [syndrome\_impostor](https://yeswehack.com/hunters/syndrome-impostor) as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-qpg6-635j-wjc2](https://github.com/opf/openproject/security/advisories/GHSA-qpg6-635j-wjc2)

### CVE-2026-27717 - IDOR on OpenProject allows any user to overwrite any sprint/version title

An attacker can overwrite the Sprint/Version titles of any project in the same instance/using the same database.

This vulnerability was reported by user posisec as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-p3hw-5g6p-69f2](https://github.com/opf/openproject/security/advisories/GHSA-p3hw-5g6p-69f2)

### CVE-2026-27718 - Stored HTML Injection via MentionFilter Bypass Leads to Credential Harvesting in Email Notifications

A stored HTML injection vulnerability exists in OpenProject&#39;s Markdown rendering pipeline. The MentionFilter decodes HTML entities after the SanitizationFilter has already run, allowing an attacker to inject arbitrary HTML into work package comments. This HTML is stored server-side and rendered without sanitization in email notifications sent to all watchers, assignees, and mentioned users, causing confusion about inserted elements.

This vulnerability was reported by user [s-sploit-c](https://yeswehack.com/hunters/s-sploit-c) as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-cxm3-9m5g-9cq4](https://github.com/opf/openproject/security/advisories/GHSA-cxm3-9m5g-9cq4)

### CVE-2026-27719 - Authorization flaw in API grids endpoint leads to erase another user widget

The vulnerability is an IDOR/authorization flaw in the My Page grid widgets that allows any authenticated user to delete arbitrary queries by ID. The My Page widgets for work packages accept a queryId inside the widget options. This queryId is stored without any permission checks, and when the widget is removed, a server-side after\_destroy hook deletes the query referenced by that queryId.

This vulnerability was reported by user Edia\_r as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-7xv7-73x4-qqvp](https://github.com/opf/openproject/security/advisories/GHSA-7xv7-73x4-qqvp)

### CVE-2026-27720 - IDOR on backlog stories allows leaking of work package subject

The `RbStoriesController` calls `Story.find(params[:id])` without scoping to the current project or visibility.

By causing an update to the Story with a subject longer than 255 characters, the update is rejected, which results in the original title being returned in the HTTP response.

Since user stories are mapped to work packages\[1\], this allows reading out the title of any work package just by providing the incrementing work package ID.

This vulnerability was reported by user posisec as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-xfmm-g339-3x85](https://github.com/opf/openproject/security/advisories/GHSA-xfmm-g339-3x85)

### CVE-2026-27721 - Improper Authentication on OpenProject through /oauth/authorize via GET parameter "redirect_uri" when using mobile OAuth app

OpenProject permits the registration of custom URI schemes (e.g., openprojectapp://) for OAuth callbacks without enforcing PKCE (Proof Key for Code Exchange) or validating the exclusivity of the destination application (via Universal Links).

By intercepting this code, an attacker with access to the mobile device can exchange it for an access token (as the client is &quot;Public&quot; and has no secret), effectively hijacking the user&#39;s session and gaining full API access to their account

This vulnerability was reported by user wayward as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-w92f-h4wh-g4w4](https://github.com/opf/openproject/security/advisories/GHSA-w92f-h4wh-g4w4)

### CVE-2026-27722 - IDOR on OpenProject through /meetings/{meeting_id}/agenda_items/{id}/move_to_section via POST request

There is an Insecure Direct Object Reference (IDOR) in the `MeetingAgendaItemsController#move_to_section endpoint`. This allows an authenticated user to perform Meeting Agenda Pollution by moving their own agenda items into any meeting section of any other project.

While the initial agenda item is loaded from the authorized meeting context, the controller fails to validate that the target `meeting_section_id` belongs to the same project or a project where the user has permission.

This vulnerability was reported by user Herdiyan Adam Putra (herdiyanitdev) as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-xw8w-4qxm-g9gv](https://github.com/opf/openproject/security/advisories/GHSA-xw8w-4qxm-g9gv)

### CVE-2026-27731 - IDOR on OpenProject via PUT /work_packages/[workPackageId]/activities/[activityId]/toggle_reaction allows reader user to read internal comments

A missing permission check on the endpoint to add an emoji reaction to a comment allows an attacker to add an emoji reaction to internal comments, even if they do not have access to internal comments. To correctly display the information in the frontend, the server returns the complete internal comment with the added emoji reaction to the attacker. This allows the attacker by guessing the ID of an internal comment, to access those comments without the permission to see them.

This vulnerability was reported by user tuannq\_gg as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-3qgp-q2x5-c4jw](https://github.com/opf/openproject/security/advisories/GHSA-3qgp-q2x5-c4jw)

### CVE-2026-27733 - Authorization bypass via MCP endpoint

If the MCP server is enabled in the application, users that do not have access to enumerate `Status` or `Types` could access those resources without proper permission checks via the MCP server.

This vulnerability was reported by users noidont and [syndrome\_impostor](https://yeswehack.com/hunters/syndrome-impostor) as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-w9w6-f59w-89vj](https://github.com/opf/openproject/security/advisories/GHSA-w9w6-f59w-89vj)

### CVE-2026-27817 - Missing boundary check allows users with Manage Agenda Items permission in one project to create Agenda Items in Meetings in other projects

When creating meeting agenda items, the code did properly check that the section an agenda item should be put into belongs to the meeting provided in the URL. This lead to a user with the _Manage Meeting Agendas_ permission in one project to be able to add meeting agenda items to every meeting in the instance. Together with the response about the creation of the meeting agenda item, certain meeting details including

- Status of the meeting

- Creator of the meeting

- Date and Time range of the meeting

No other details of the meeting information were exposed.

This vulnerability was reported by user [sam91281](https://yeswehack.com/hunters/sam91281) as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-c76v-8735-35hq](https://github.com/opf/openproject/security/advisories/GHSA-c76v-8735-35hq)

### CVE-2026-27827 - Insecure Direct Object Reference in Project Storage Administration Theft & Pre-Auth Remote Folder Deletion

An unscoped loading of Project Storages lead to users with the _Manage Files in Project_ permission in one project, to access project storages in other projects. This would give information about the storage that they were not supposed to see.&nbsp;

Additionally, for storages with automatic project folder management, when a deletion of the project folder was triggered, the deletion in the file storage was triggered before the permission check was executed. Together with the unscoped loading above, this allowed users with _Manage Files in Project permission in one project, to delete automatically managed folders in file storages that they did not have access to._

This vulnerability was reported by user cavid as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-v8cr-7x8f-78mq](https://github.com/opf/openproject/security/advisories/GHSA-v8cr-7x8f-78mq)

<!-- END CVE AUTOMATED SECTION -->

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Error when creating a new work package after uploading an attachment to the previous one that was opened in details view \[[#67980](https://community.openproject.org/wp/67980)\]
- Bugfix: Pasting rich text into CKEditor crashes it \[[#69597](https://community.openproject.org/wp/69597)\]
- Bugfix: external\_redirect URL always engaged, making copy&amp;pasting links harder \[[#71946](https://community.openproject.org/wp/71946)\]
- Bugfix: Parent project name visible in breadcrumb irrespective of parent access \[[#71972](https://community.openproject.org/wp/71972)\]
- Bugfix: Trying to attach a calendar part when no mail is being generated fails \[[#72244](https://community.openproject.org/wp/72244)\]
- Bugfix: Meetings appear duplicate in the ical subscription after an interim response \[[#72259](https://community.openproject.org/wp/72259)\]
- Bugfix: Can&#39;t create automatically managed project folder when project name contains forbidden Nextcloud characters \[[#72525](https://community.openproject.org/wp/72525)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions

A big thanks to our Community members for reporting bugs and helping us identify and provide fixes.
This release, special thanks for reporting and finding bugs go to Александр Татаринцев, Slavur Jones.
