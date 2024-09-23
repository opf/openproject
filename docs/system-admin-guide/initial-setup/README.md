---
sidebar_navigation:
  title: Initial setup
  priority: 999
description: Getting started as an system administrator in OpenProject
keywords: initial setup, initial configuration in frontend
---

# Initial setup of OpenProject for administrators

This section will guide you through some basic recommendations for setting up your OpenProject instance as a system administrator and for preparing it for its users.
For the backend setup and initial technical configurations for on-premise editions please have a look at the [respective section](../../installation-and-operations/installation/packaged/#initial-configuration) in the installation guide.

Before adding users we recommend to check and configure the following topics:

| Topic                                                            | What to set up                                                    |
|------------------------------------------------------------------|:------------------------------------------------------------------|
| [Language settings](../system-settings/languages/)               | Set up available languages                                        |
| [User settings](../users-permissions/settings/)                  | Default user settings, user deletion, user consent                |
| [Roles and permissions](../users-permissions/roles-permissions/) | What users can do (Roles) and the permissions for those roles     |
| [User groups](../users-permissions/groups/)                      | Create groups that are linked to projects, with a role, and users |
| [Avatars](../users-permissions/avatars/)                         | Allow users to upload their photo or Gravatar                     |
| [Calendars and dates](../calendars-and-dates/)                   | Default working days and time and date formats                    |
| [General settings](../system-settings/general-settings/)         | Set host name, protocol and welcome text                          |
| [Authentication](../authentication/)                             | Set up authentication methods for users                           |
| [Announcements](../announcement/)                                | Set an announcement to be shown to users on login                 |
| [Start page](../../user-guide/home/)                             | Set up the home page, shown after login                           |

If required, especially for on-premises versions, it might make sense to have a look at these sections, too:

| Topic                                                                                         | What to set up                          |
|-----------------------------------------------------------------------------------------------|:----------------------------------------|
| [Configure outbound emails](../../installation-and-operations/configuration/outbound-emails/) | Set up SMTP on the server to send email |
| [Configure incoming emails](../../installation-and-operations/configuration/incoming-emails/) | Receiving email by the server           |
