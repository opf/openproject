---
title: OpenProject 17.6.0
sidebar_navigation:
    title: 17.6.0
release_version: 17.6.0
release_date: 2026-06-08
---

# OpenProject 17.6.0

Release date: 2026-06-08

We released [OpenProject 17.6.0](https://community.openproject.org/versions/2298).
The release contains several bug fixes and we recommend updating to the newest version.
In these Release Notes, we will give an overview of important feature changes. At the end, you will find a complete list of all changes and bug fixes.
## Important feature changes

<!-- Inform about the major features in this section -->

## Important updates and breaking changes

### Integrations (e.g. Nextcloud and XWiki) respect global SSRF filters

To increase the security of OpenProject installations, we've added protections against server-side request forgery in previous releases
of OpenProject. These prevent OpenProject from making network requests into private IP address space.

Starting with OpenProject 17.6, these protections expand into the code that's responsible for web requests of storage and wiki integrations as well.
This means if you have a Nextcloud instance or an XWiki instance reachable via a private (i.e. not publicly routable) IP address, you need to
add it to the SSRF allowlist to be able to keep the integration working. This is usually achieved by defining the following environment variable:

```
OPENPROJECT_SSRF_PROTECTION_IP_ALLOWLIST=2001:db8:100::/48
```

The list accepts one or multiple IP addresses or ranges (in CIDR notation) that shall be exempt from SSRF filtering.

### Meeting API structure changes

17.6. introduces new endpoints for meeting outcomes,
and changes the self link for all meeting related resources to be flat:

That means, some of the responses have changed:

POST/PATCH/DELETE `/api/v3/meetings/:id/agenda_items)` is no longer available,
they have been moved to the `/api/v3/meeting_agendas/` respectively. The same is true for outcomes and sections.

This follows the APIv3 standards, and also fixes a bug related to the self link.

<!-- BEGIN SECURITY FIXES AUTOMATED SECTION -->

<!-- END SECURITY FIXES AUTOMATED SECTION -->
<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Feature: Sprint goals \[[#71059](https://community.openproject.org/wp/71059)\]
- Feature: Add possibility to order backlog buckets and sprints manually \[[#73610](https://community.openproject.org/wp/73610)\]
- Feature: Add multi-select drop-down for sprint and backlog buckets \[[#73611](https://community.openproject.org/wp/73611)\]
- Feature: Multi-select cards within backlog and sprints \[[#73729](https://community.openproject.org/wp/73729)\]
- Feature: Display backlog bucket in work package page \[[#73887](https://community.openproject.org/wp/73887)\]
- Feature: &quot;Move to backlog bucket&quot; and &quot;move to backlog inbox&quot; menu option for work packages within the backlog module \[[#73925](https://community.openproject.org/wp/73925)\]
- Feature: Add existing work packages within sprint and backlog containers menu \[[#74386](https://community.openproject.org/wp/74386)\]
- Feature: &quot;All sprints&quot; view - simple list \[[#74594](https://community.openproject.org/wp/74594)\]
- Feature: Column, ordering and grouping by backlog bucket in work package list \[[#74653](https://community.openproject.org/wp/74653)\]
- Feature: Show message when work package with excluded type/status is moved to backlog and disappears \[[#74845](https://community.openproject.org/wp/74845)\]
- Feature: Check the accessibility on Flash messages \[[#63276](https://community.openproject.org/wp/63276)\]
- Feature: Remove newest projects in project widget on homepage \[[#74198](https://community.openproject.org/wp/74198)\]
- Feature: Make project hierarchy collapsable in the global project selector \[[#74625](https://community.openproject.org/wp/74625)\]
- Feature: Create work package out of Meeting Agenda Item \[[#57053](https://community.openproject.org/wp/57053)\]
- Feature: API for Meeting outcomes \[[#75393](https://community.openproject.org/wp/75393)\]
- Feature: Group synchronization through attributes of the group, not member/memberOf \[[#32812](https://community.openproject.org/wp/32812)\]
- Feature: Track working hours and availabilities for each user in the system \[[#34911](https://community.openproject.org/wp/34911)\]
- Feature: Allow cost types to be enabled/disabled per project \[[#42037](https://community.openproject.org/wp/42037)\]
- Feature: All open view with default sort order to show the latest on top (ID descending) \[[#57962](https://community.openproject.org/wp/57962)\]
- Feature: New Administration for User Custom Fields and Custom Field Sections \[[#72005](https://community.openproject.org/wp/72005)\]
- Feature: Primerize advanced filters component \[[#74380](https://community.openproject.org/wp/74380)\]
- Feature: Build Primer quickfilter \[[#74577](https://community.openproject.org/wp/74577)\]
- Feature: Enforce order of subheader slots/quickfilters \[[#75013](https://community.openproject.org/wp/75013)\]
- Feature: Escape possible control characters in CSV export \[[#75486](https://community.openproject.org/wp/75486)\]
- Feature: Filter project by portfolio and programm \[[#74718](https://community.openproject.org/wp/74718)\]
- Feature: Adapt Excel and CSV exports for semantic identifiers \[[#74361](https://community.openproject.org/wp/74361)\]
- Feature: Adapt BCF Export and Import for semantic identifiers \[[#74362](https://community.openproject.org/wp/74362)\]
- Feature: Adapt other PDF exports for semantic identifiers \[[#75229](https://community.openproject.org/wp/75229)\]
- Feature: /wp on an empty line should create a block work-package link, not an inline one \[[#75310](https://community.openproject.org/wp/75310)\]
- Feature: Expose installation UUID via API \[[#75442](https://community.openproject.org/wp/75442)\]
- Feature: Configure internal wiki provider \[[#75594](https://community.openproject.org/wp/75594)\]
- Feature: Show total sprint capacity (in days or story points) \[[#71060](https://community.openproject.org/wp/71060)\]
- Feature: &quot;All Sprints&quot; view \[[#71260](https://community.openproject.org/wp/71260)\]
- Feature: Allow multiple active sprints within a single project \[[#73232](https://community.openproject.org/wp/73232)\]
- Feature: XWiki integration \[[#53738](https://community.openproject.org/wp/53738)\]
- Feature: Extend CKEditor with Wiki interactions and macros \[[#70554](https://community.openproject.org/wp/70554)\]
- Feature: Wiki tab in work package detail view \[[#70555](https://community.openproject.org/wp/70555)\]
- Feature: Wiki integration setup on OpenProject \[[#70556](https://community.openproject.org/wp/70556)\]
- Bugfix: Page loads twice after sprint creation \[[#73316](https://community.openproject.org/wp/73316)\]
- Bugfix: A missing full stop at the end of confirmation message of danger dialog  \[[#73899](https://community.openproject.org/wp/73899)\]
- Bugfix: Impossible to open work packages list from the sidebar after visiting team planner \[[#74331](https://community.openproject.org/wp/74331)\]
- Bugfix: Input group with trailing action clipboard copy button + validation error = style broken \[[#75395](https://community.openproject.org/wp/75395)\]
- Bugfix: FilterableTreeView does not keep default filter arguments  \[[#75617](https://community.openproject.org/wp/75617)\]
- Bugfix: Tree view selection based on path identity breaks use cases where similar paths are allowed \[[#75618](https://community.openproject.org/wp/75618)\]
- Bugfix: Fix tracking expression browser warnings \[[#75676](https://community.openproject.org/wp/75676)\]
- Bugfix: GET /api/v3/meetings/{id} — \_links.participants count does not match \_embedded.participants count \[[#75696](https://community.openproject.org/wp/75696)\]
- Bugfix: PATCH /api/v3/meetings/{id} — adding an already existing participant via \_links.participants creates a duplicate entry \[[#75697](https://community.openproject.org/wp/75697)\]
- Bugfix: PATCH /api/v3/meetings/{id} - participants cannot be removed via \_links.participants \[[#75701](https://community.openproject.org/wp/75701)\]
- Bugfix: WP table configuration: overflow due to the very long CF label \[[#46005](https://community.openproject.org/wp/46005)\]
- Bugfix: Tooltip on Team planner not entirely visible  \[[#48223](https://community.openproject.org/wp/48223)\]
- Bugfix: Problems with GitLab and GitHub integration snippets \[[#56847](https://community.openproject.org/wp/56847)\]
- Bugfix: Misalignment of fields in Work estimates and progress when language=DE \[[#65738](https://community.openproject.org/wp/65738)\]
- Bugfix: Custom text widget pagination bug \[[#66419](https://community.openproject.org/wp/66419)\]
- Bugfix: Arrow for switching years barely visible in dark mode on the calendar \[[#68517](https://community.openproject.org/wp/68517)\]
- Bugfix: Login right side panel dark mode: login form has ugly/unnecessary gray background  \[[#69328](https://community.openproject.org/wp/69328)\]
- Bugfix: User sees a success banner if they save a letter/word as integer \[[#71650](https://community.openproject.org/wp/71650)\]
- Bugfix: Closed, duplicated meeting disappears from synced calendar \[[#72219](https://community.openproject.org/wp/72219)\]
- Bugfix: Wrong icon used when changing non working days \[[#73372](https://community.openproject.org/wp/73372)\]
- Bugfix: User facing work package link from GitLab tab is not the shortened version \[[#73718](https://community.openproject.org/wp/73718)\]
- Bugfix: Inline text attachments lose UTF-8 charset \[[#75402](https://community.openproject.org/wp/75402)\]
- Bugfix: BCF import permission scope not clear \[[#75457](https://community.openproject.org/wp/75457)\]
- Bugfix: Hide &quot;my meetings&quot; and &quot;favourited projects&quot; widgets for anonymous users \[[#75477](https://community.openproject.org/wp/75477)\]
- Bugfix: Setting mail header via OPENPROJECT\_EMAILS\_\_HEADER\_EN interprets colon as hash \[[#75570](https://community.openproject.org/wp/75570)\]
- Bugfix: Date custom field filter &quot;is empty&quot; does not return all work packages with empty values \[[#75185](https://community.openproject.org/wp/75185)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions
A very special thank you goes to our sponsors for this release.
Also a big thanks to our Community members for reporting bugs and helping us identify and provide fixes.
Special thanks for reporting and finding bugs go to Rince wind, Walid Ibrahim, Gábor Alexovics, Brandon Soonaye, Mohammed Mohiuddin.

Last but not least, we are very grateful for our very engaged translation contributors on Crowdin, who translated quite a few OpenProject strings!
Would you like to help out with translations yourself?
Then take a look at our translation guide and find out exactly how you can contribute.
It is very much appreciated!
