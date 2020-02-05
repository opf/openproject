---
title: OpenProject 9.0.2
sidebar_navigation:
    title: 9.0.2
release_version: 9.0.2
release_date: 2019-06-13
---

# OpenProject 9.0.2

We released [OpenProject 9.0.2](https://community.openproject.com/versions/1359).
The release contains several bug fixes and we recommend updating to the newest version. If you're running OpenProject with a relative URL root (e.g., under domain.example.org/openproject), this update should fix [an installation issue related to Sass compilation](https://community.openproject.com/wp/30372) as well as [an error trying to use create new boards](https://community.openproject.com/wp/30370).



#### Bug fixes and changes

- **Fixed**: Wiki TOC doesn't render headings properly [[#30245](https://community.openproject.com/wp/30245)]
- **Fixed**: Cannot create new boards in installations with relative_url_root set [[#30370](https://community.openproject.com/wp/30370)]
- **Fixed**: Sass compilation fails on packaged installations with relative_url_root set [[#30372](https://community.openproject.com/wp/30372)]
- **Fixed**: Chrome is logged out when accessing pages with images on S3 storage [[#28652](https://community.openproject.com/wp/28652)]
- **Fixed**: OpenProject logo on My page does not redirect to landing page [[#30376](https://community.openproject.com/wp/30376)]
- **Fixed**: The PDF export is cut off after the first page [[#29929](https://community.openproject.com/wp/29929)]

