---
title: OpenProject 9.0.3
sidebar_navigation:
    title: 9.0.3
release_version: 9.0.3
release_date: 2019-07-23
---

# OpenProject 9.0.3

We released [OpenProject 9.0.3](https://community.openproject.com/versions/1376).
The release contains several bug fixes and we recommend updating to the newest version.



#### Bug fixes and changes

- Changed: Searching for Custom Fields [[#29756](https://community.openproject.com/wp/29756)]
- Changed: Prevent collisions between users working on the same board [[#30403](https://community.openproject.com/wp/30403)]
- Changed: Do not send email notifications for changes in child work packages [[#30532](https://community.openproject.com/wp/30532)]
- Fixed: Version field flickers [[#30356](https://community.openproject.com/wp/30356)]
- Fixed: Missing translations for boards [[#30367](https://community.openproject.com/wp/30367)]
- Fixed: Work package description not updated after initial edit [[#30373](https://community.openproject.com/wp/30373)]
- Fixed: Parent work package in Gantt chart not displayed correctly [[#30388](https://community.openproject.com/wp/30388)]
- Fixed: Cannot delete date from work packages of a type that is a milestone [[#30390](https://community.openproject.com/wp/30390)]
- Fixed: Work packages in closed version suggest status editable but then nothing happens [[#30396](https://community.openproject.com/wp/30396)]
- Fixed: Wrong language is displayed in some date fields [[#30400](https://community.openproject.com/wp/30400)]
- Fixed: Project Paisy: Connecting functional document fails without error message [[#30404](https://community.openproject.com/wp/30404)]
- Fixed: Button Release to production not visible for Releasemanager [[#30405](https://community.openproject.com/wp/30405)]
- Fixed: Text references to SVN revisions don't create links [[#30415](https://community.openproject.com/wp/30415)]
- Fixed: User with :manage_boards but without :manage_public_queries can create faulty board columns [[#30426](https://community.openproject.com/wp/30426)]
- Fixed: Tag shown on My page for time tracking comments [[#30432](https://community.openproject.com/wp/30432)]
- Fixed: [Error 500] An error occurred on the page you were trying to access [[#30435](https://community.openproject.com/wp/30435)]
- Fixed: OmniAuth login link in top menu not styled properly. [[#30436](https://community.openproject.com/wp/30436)]
- Fixed: Board list not sorted alphabetically [[#30444](https://community.openproject.com/wp/30444)]
- Fixed: Not all multiples of 4096 bytes are folders [[#30450](https://community.openproject.com/wp/30450)]
- Fixed: Search work package hints are not links [[#30457](https://community.openproject.com/wp/30457)]
- Fixed: New API-backed attachments always use content disposition attachment [[#30492](https://community.openproject.com/wp/30492)]
- Fixed: Can not switch to hierarchy mode in work packages list [[#30514](https://community.openproject.com/wp/30514)]
- Fixed: Error when copying a work package [[#30518](https://community.openproject.com/wp/30518)]
- Fixed: Gantt chart: Jump when scheduling finish date of work package with only start date [[#30554](https://community.openproject.com/wp/30554)]
- Fixed: Comma and dot flipped for values in cost report and budgets (German language setting) [[#30574](https://community.openproject.com/wp/30574)]
- Fixed: Inline-create useless when only add_work_packages_permission present [[#30589](https://community.openproject.com/wp/30589)]
- Fixed: Cannot close Arbeitspaket [[#30590](https://community.openproject.com/wp/30590)]
- Fixed: "Login" instead of "Login name" used (causes problems with translations) [[#30591](https://community.openproject.com/wp/30591)]
- Fixed: Board links in sidebar broken [[#30595](https://community.openproject.com/wp/30595)]

#### Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to
Marc Vollmer, Jonathan Brisebois, Michael Wood, Jason Culligan, Erhan Sahin, otheus uibk, Frank Hintsch
