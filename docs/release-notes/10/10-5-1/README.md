---
title: OpenProject 10.5.1
sidebar_navigation:
    title: 10.5.1
release_version: 10.5.1
release_date: 2020-05-06
---

# OpenProject 10.5.1

We released [OpenProject 10.5.1](https://community.openproject.com/versions/1426).
The release contains several bug fixes and we recommend updating to the newest version.

<!--more-->
#### Bug fixes and changes

- Fixed: Remove horizontal line in several modules above buttons \[[#32924](https://community.openproject.com/wp/32924)\]
- Fixed: Alignment for assignee in Gantt chart off \[[#33097](https://community.openproject.com/wp/33097)\]
- Fixed: Scale for spent time widget wrong (especially when logging a lot of time on same day) \[[#33128](https://community.openproject.com/wp/33128)\]
- Fixed: bcf api is called although bim is disabled for the instance \[[#33130](https://community.openproject.com/wp/33130)\]
- Fixed: Search instead of work package is shown when entering id and pressing enter in search in quick succession \[[#33137](https://community.openproject.com/wp/33137)\]
- Fixed: Wiki CKEditor5 toolbar no longer sticky \[[#33144](https://community.openproject.com/wp/33144)\]
- Fixed: Number vanishes in time logging widget \[[#33185](https://community.openproject.com/wp/33185)\]
- Fixed: Main menu doesn't open when resized to 0 width \[[#33188](https://community.openproject.com/wp/33188)\]
- Fixed: BCF thumbnail column available in non-bim instances \[[#33190](https://community.openproject.com/wp/33190)\]
- Fixed: Missing translation for default assignee board name \[[#33193](https://community.openproject.com/wp/33193)\]
- Fixed: Avoid selecting text while resizing main menu \[[#33194](https://community.openproject.com/wp/33194)\]
- Fixed: Assignee board breaks in sub url \[[#33202](https://community.openproject.com/wp/33202)\]
- Fixed: n+1 query in work package list (for bcf_issues) \[[#33234](https://community.openproject.com/wp/33234)\]
- Fixed: Avoid sending mails on seeding \[[#33245](https://community.openproject.com/wp/33245)\]
- Fixed: Error 500 when comparing meeting versions / diffs \[[#33253](https://community.openproject.com/wp/33253)\]
- Changed: Fulltext autocompletion for work packages 2.0 \[[#33133](https://community.openproject.com/wp/33133)\]
