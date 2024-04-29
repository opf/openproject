---
title: OpenProject 12.0.7
sidebar_navigation:
    title: 12.0.7
release_version: 12.0.7
release_date: 2022-01-26
---

# OpenProject 12.0.7

Release date: 2022-01-26

We released [OpenProject 12.0.7](https://community.openproject.org/versions/1506).
The release contains several bug fixes and we recommend updating to the newest version.

## API default max page sizes

In previous versions of OpenProject, the max API page size is controlled by the maximum page size in the "Per page options". This is not clear and causes issues when trying to request larger page sizes (such as for autocompleters). For example, larger instances reported missing options for users and projects.

There is now a separate setting for the max API size that will be used for these autocompleters. You can find it in Administration > System settings > API.

## Russian expletive translations

OpenProject relies on community translations for some languages that we cannot provide translations for ourselves. It was brought to our attention that the Russian translations partially contain expletive languages. Thanks to community contributors Sergey and Christina, these translations were fixed on crowdin and could now be included into the release.

We need your help to improve and extend translations of OpenProject into your native language. To get more information, please see our [Translating OpenProject guide](../../../development/translate-openproject/) and our [project on crowdin.com](https://crowdin.com/project/openproject), where you can provide and help approve translations from your browser. If you wish to become a proofreader for your language, please reach out to [info@openproject.com](mailto:info@openproject.com)

## Custom plugins in packaged installations

If you were using custom plugins, the build of the OpenProject frontend failed due to a Gemfile lock issue as well as an angular error. Both of these issues were fixed.

## Bug fixes and changes

- Fixed: Custom plugins not working with 11.0.1 \[[#35103](https://community.openproject.org/wp/35103)\]
- Fixed: \[Repository\] GIT Referencing and time tracking not work in branch \[[#39796](https://community.openproject.org/wp/39796)\]
- Fixed: Disable send_notifications on instantiating new project from template \[[#40348](https://community.openproject.org/wp/40348)\]
- Fixed: Only last N projects available for parent project selection \[[#40580](https://community.openproject.org/wp/40580)\]
- Fixed: Change labels in Russian (expletive) \[[#40581](https://community.openproject.org/wp/40581)\]
- Fixed: Dropdown menu of parent child board not showing all WPs \[[#40647](https://community.openproject.org/wp/40647)\]
- Fixed: Unread, no longer visible notifications still showing up in total \[[#40747](https://community.openproject.org/wp/40747)\]
- Fixed: Synchronized group creation error \[[#40750](https://community.openproject.org/wp/40750)\]
- Fixed: Plugin Installation: Angular fronted doesn't compile \[[#40781](https://community.openproject.org/wp/40781)\]
- Fixed: Date picker is displayed in wrong spot \[[#40789](https://community.openproject.org/wp/40789)\]
- Fixed: Wiki not available anymore \[[#40790](https://community.openproject.org/wp/40790)\]
- Fixed: Custom fields disappearing after attachment upload \[[#40826](https://community.openproject.org/wp/40826)\]
- Changed: Add separate APIv3 page size limit \[[#40816](https://community.openproject.org/wp/40816)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to
Gábor Sift, Frank Schmid, Christina Vechkanova, George Plant, Ivo Maffei
