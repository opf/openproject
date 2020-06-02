---
title: OpenProject 10.6.0
sidebar_navigation:
    title: 10.6.0
release_version: 10.6.0
release_date: 2020-06-02
---

# OpenProject 10.6.0

We released [OpenProject 10.6.0](https://community.openproject.com/versions/1416).
The release contains several bug fixes and we recommend updating to the newest version.

<!--more-->
#### Bug fixes and changes

- Epic: Aggregate activity entries \[[#23744](https://community.openproject.com/wp/23744)\]
- Fixed: Date picker allows selection a year for only the next 10 years. Needs to increase. \[[#29413](https://community.openproject.com/wp/29413)\]
- Fixed: Weird date format at meetings page \[[#32986](https://community.openproject.com/wp/32986)\]
- Fixed: [Work packages] Custom fields for long text \[[#33143](https://community.openproject.com/wp/33143)\]
- Fixed: .xls exports of cost reports use incorrect decimal precision \[[#33149](https://community.openproject.com/wp/33149)\]
- Fixed: Button to log time is shown even if I do not have the permissions \[[#33152](https://community.openproject.com/wp/33152)\]
- Fixed: Main menu element is not correctly highlighted when creating a new category \[[#33154](https://community.openproject.com/wp/33154)\]
- Fixed: Main menu resizer icon not draggable \[[#33187](https://community.openproject.com/wp/33187)\]
- Fixed: Work Package - Comment can only be edited once per description call \[[#33200](https://community.openproject.com/wp/33200)\]
- Fixed: Assignee board breaks in sub url \[[#33202](https://community.openproject.com/wp/33202)\]
- Fixed: Logged time widget does not update correctly \[[#33217](https://community.openproject.com/wp/33217)\]
- Fixed: OAuth settings and docs both do not provide information for endpoints \[[#33241](https://community.openproject.com/wp/33241)\]
- Fixed: Time Tracking Issue After update OpenProject 10.5.2 (PostgreSQL) \[[#33310](https://community.openproject.com/wp/33310)\]
- Fixed: Timeout / error 500 when setting current unit cost rate \[[#33319](https://community.openproject.com/wp/33319)\]
- Fixed: Form misplaced after error \[[#33324](https://community.openproject.com/wp/33324)\]
- Fixed: Create child in work package list does not create parent-child relationship \[[#33329](https://community.openproject.com/wp/33329)\]
- Fixed: Oauth endpoints need to allow target hosts in CSP header "form-action" \[[#33336](https://community.openproject.com/wp/33336)\]
- Fixed: Time logging not possible with custom field of type "version" \[[#33378](https://community.openproject.com/wp/33378)\]
- Fixed: Mailing configuration appears not to be reloaded in workers \[[#33413](https://community.openproject.com/wp/33413)\]
- Fixed: OpenProject | Usability bug: layout bug when setting new parent \[[#33449](https://community.openproject.com/wp/33449)\]
- Fixed: Clicking on info icon on card view doesn't do anything \[[#33451](https://community.openproject.com/wp/33451)\]
- Fixed: Fetching recent work packages when logging time fails with internal error \[[#33472](https://community.openproject.com/wp/33472)\]
- Changed: Show Project name in Card View \[[#31556](https://community.openproject.com/wp/31556)\]
- Changed: Use angular modal for time logging throughout the application \[[#32126](https://community.openproject.com/wp/32126)\]
- Changed: Add icon "Log time" close to spent time attribute in work packages details view \[[#32129](https://community.openproject.com/wp/32129)\]
- Changed: Make cancel buttons consistent \[[#32919](https://community.openproject.com/wp/32919)\]
- Changed: Improve styling for the news widget \[[#32926](https://community.openproject.com/wp/32926)\]
- Changed: Add notification message to assignee board when no project members \[[#33073](https://community.openproject.com/wp/33073)\]
- Changed: Extend token structure with attributes company and domain \[[#33129](https://community.openproject.com/wp/33129)\]
- Changed: Move "log time" icon outside of the hover highlighting \[[#33307](https://community.openproject.com/wp/33307)\]
- Changed: Allow defining CA path of LDAP connection \[[#33345](https://community.openproject.com/wp/33345)\]
- Changed: Enable more table features in texteditor \[[#33349](https://community.openproject.com/wp/33349)\]
- Changed: Enable Projects for outgoing Webhooks \[[#33355](https://community.openproject.com/wp/33355)\]
- Changed: New Features teaser for 10.6 \[[#33470](https://community.openproject.com/wp/33470)\]

#### Contributions
A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Marc Vollmer, Ricardo Vigatti, Sébastien VITA, Tino Breddin, Lukas Zeil, Rajesh Vishwakarma, Gio @ Enuan, Harald Holzmann
