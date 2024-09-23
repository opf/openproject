---
title: OpenProject 8.0.2
sidebar_navigation:
  title: 8.0.2
release_version: 8.0.2
release_date: 2018-10-23
---


# OpenProject 8.0.2

We released
[OpenProject 8.0.2](https://community.openproject.org/versions/1154).
The release contains several bug fixes and we recommend updating to the
newest version.

## Bug fixes and changes

  - Fixed: Relations cannot be added when OpenProject is running on
    relative URL root
    \[[#28639](https://community.openproject.org/wp/28639)\]
  - Fixed: Cannot select values for custom field filter
    \[[#28739](https://community.openproject.org/wp/28739)\]
  - Fixed: Renaming custom field does not invalidate cache
    \[[#28738](https://community.openproject.org/wp/28738)\]
  - Fixed: Top menu entries are misaligned in mobile views
    \[[#28678](https://community.openproject.org/wp/28678)\]
  - Fixed: Unable to save
    Sub-Project
    with Custom Field of
    Version
    using parent
    Version
    \[[#28421](https://community.openproject.org/wp/28421)\]
  - Fixed: Toolbar container styling corrected
    \[[#28645](https://community.openproject.org/wp/28645)\]
  - Fixed: Content-Disposition was not set for AWS hosted attachments
    for non-inlinable images. This resulted in SVGs being displayed
    inline, which opens an SVG XSS attack vector on the AWS domain (NOT
    on the OpenProject domain). From this version onward, non-image
    files will receive a forced *attachment* content disposition to
    ensure the file is not loaded in the browser.

## Contributions

Thanks to Github users @storm2513 and @akasparas for providing bugfixes
as pull requests [on our GitHub
project](https://github.com/opf/openproject).  A big thanks to community
members for reporting bugs and helping us identifying and providing
fixes.
