---
title: OpenProject 10.2.2
sidebar_navigation:
    title: 10.2.2
release_version: 10.2.2
release_date: 2019-12-11
---

# OpenProject 10.2.2

We released [OpenProject 10.2.2](https://community.openproject.com/versions/1405).
The release contains several bug fixes and fixes server security issues. We thus urge everybody to upgrade to the newest version as soon as possible.

<!--more-->
#### Bug fixes and changes

- Fixed: Outline of display-field extends table cell width \[[#31214](https://community.openproject.com/wp/31214)\]
- Fixed: SQL error in work package view \[[#31667](https://community.openproject.com/wp/31667)\]
- Fixed: Error in OpenProject::Patches::ActiveRecordJoinPartPatch module after ActiveRecord updating to 6 version \[[#31673](https://community.openproject.com/wp/31673)\]
- Fixed: [WorkPackages] "group by"-header line to short \[[#31720](https://community.openproject.com/wp/31720)\]
- Fixed: Second level menu of boards is not reachable on first click \[[#31721](https://community.openproject.com/wp/31721)\]
- Fixed: Doubled scrollbar in sidebar when "Buy Now" teaser is activated \[[#31729](https://community.openproject.com/wp/31729)\]
- Fixed: Main menu width is lost after closing it \[[#31730](https://community.openproject.com/wp/31730)\]
- Fixed: Dropdown for table highlighting configuration is off place \[[#31732](https://community.openproject.com/wp/31732)\]
- Fixed: Double click on WP row not working \[[#31737](https://community.openproject.com/wp/31737)\]
- Fixed: Unverified CSRF request in create budget form \[[#31739](https://community.openproject.com/wp/31739)\]
- Fixed: Selected long cf values are reduced to ... in ng-select \[[#31765](https://community.openproject.com/wp/31765)\]
- Fixed: Webhook is failing/crashing due to NameError \[[#31809](https://community.openproject.com/wp/31809)\]
- Fixed: API v3 /relations/:id does not check permissions \[[#31855](https://community.openproject.com/wp/31855)\]
- Fixed: Tabnabbing on wiki pages \[[#31817](https://community.openproject.com/wp/31817)\]

#### Contributions
A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

In this release, we would especially like to thank Bartosz Nowicki for responsibly disclosing a severe data leakage \([#31855](https://community.openproject.com/wp/31855)\). Behaviour like this helps improving the security for everybody, so thanks a lot Bartosz. And Thanh Nguyen Nguyen of [Fortiguard Labs](https://fortiguard.com/) has once again responsibly disclosed a security issue to us ([#31817](https://community.openproject.com/wp/31817)). Thank you, Nguyen.  

We'd also like to thank users for reporting bugs:

Ihor Lavryk, Adam Vanko
