---
title: OpenProject 7.4.7
sidebar_navigation:
  title: 7.4.7
release_version: 7.4.7
release_date: 2018-07-20
---

# OpenProject 7.4.7

We released OpenProject 7.4.7. The release contains some minor fixes
regarding MessageBird adapter for Two-factor authentication.

## Work packages PDF export with images

Exporting a work package table can now optionally export image
attachments of the work package. Additional options are added to the
export modal.

## Bug fixes and changes

- Fixed: \[2FA\] Device ID not transmitted when resending with
  different channel
  \[[#28033](https://community.openproject.org/wp/28033)\]
- Fixed: \[2FA\] MessageBird: Originator may not be longer than 11
  characters \[[#28034](https://community.openproject.org/wp/28034)\]
- Fixed: \[2FA\] MessageBird:
  work-package-types/#work-package-form-configuration-premium-featureUser
  language may be
  empty \[[#28035](https://community.openproject.org/wp/28035)\]
- Fixed: \[Styling\] Prevent scrolling body when reaching bottom of
  project autocompleter
  \[[#28039](https://community.openproject.org/wp/28039)\]
