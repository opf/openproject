---
sidebar_navigation:
  title: External links
  priority: 700
description: External links settings in OpenProject.
keywords: external links, link, links, capture link, redirect, warning, external site, external website
---

# External links (Enterprise add-on)

[feature: capture_external_links ]

You can configure how OpenProject handles **external links** in formatted text (for example, project descriptions, comments, or wiki content). When enabled, external links will be intercepted and users will see a warning page before leaving the application. This helps reduce the risk of users unknowingly opening unsafe websites.

## Enable external link capture

To enable the Capture external links setting navigate to _Administration → System settings → External links_. Here you can enable the following settings: 

- **Capture external links**: when this option is turned on, all outbound links in formatted text will first lead to a warning page before users leave the application. 
- **Require users to be logged in**: when enabled, users must sign in before they can proceed to any external website.

Don't forget to save your changes. 

![Enable warning message for external links in OpenProject administration](openproject_system_admin_guide_external_links.png)

Once _Capturing external links_ is enabled, OpenProject will redirect external links in formatted text through a warning page. Here is an example of a warning page:

![Example of a warning message for an external link in OpenProject](openproject_system_admin_guide_external_links_warning_message.png)

If the requirement to be logged in is activated and users are not logged in, they will first be redirected to the login page.

## What is an external link?

Links are considered external if they:

- Are **not relative** (don’t point to the same server or application context), and
- Do **not start** with the configured **protocol** and **host name** of your OpenProject instance.
