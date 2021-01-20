---
sidebar_navigation:
  title: Integrations
  priority: 599
description: Integration to OpenProject.
robots: index, follow
keywords: projects, integration, Jira
---
# Integrations

If you have previously worked with other tools and want to switch or need an integration to OpenProject, there is a way to do so for some applications.

## GitHub

OpenProject offers a basic GitHub integration. You will find more information about the GitHub integration in our [GitHub integration guideline](../../system-admin-guide/github-integration/).

## Gitlab

The GitLab integration to OpenProject is currently being developed and you can find all information [here](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/21933#note_309977508).
We are prioritizing this topic at the moment and will update this guide with the latest developments.

## Jira

Currently, there is no direct integration between OpenProject and Jira. Since OpenProject is an excellent open source alternative to Jira, we have prepared a way to import tickets from Jira to OpenProject. First, you can export your tasks from Jira into an Excel file and then import these tasks via an [Excel plugin into OpenProject](./Excel Synchronization).

If you would like to learn more about the features of **OpenProject vs Jira** please read [here](https://www.openproject.org/jira-alternative/).

## Microsoft Project

There is an integration between MS Project and OpenProject. However, the synch plugin is not actively maintained at this time. If you wish to find out more, please [contact us](https://www.openproject.org/contact-us/).
To synchronize tasks from MS Project to OpenProject, you can export your MS Project file to Excel and then [synchronize it with OpenProject]( ./Excel Synchronization).

## Trello

Currently, there is no direct integration between OpenProject and Trello. To synchronize tasks from Trello to OpenProject, export your tasks from Trello into an Excel file and then import these tasks via an [Excel plugin into OpenProject](./Excel Synchronization).

If you would like to learn more about OpenProject's features vs Trello, please read [here](https://www.openproject.org/trello-alternative/).

## Toggl

We do offer an [integration](../time-and-costs/time-tracking/toggl-integration/) between OpenProject and the time tracking app Toggl. Find out more [here](../time-and-costs/time-tracking/toggl-integration/).

## Slack

There is a rudimentary OpenProject Slack integration. It messages a configured Slack channel, every time a Work Package or Wiki site is modified. This integration is not officially supported by OpenProject.
To activate it in the Enterprise cloud please [get in touch](https://www.openproject.org/contact-us/). For the Enterprise on-premises edition and the Community Edition you can find the plugin and its documentation on GitHub: [OpenProject Slack plugin](https://github.com/opf/openproject-slack#openproject-slack-plugin) 

## Timesheet
Currently, there is no direct integration between OpenProject and Timesheet. If you are looking for a time tracking tool with a simple push of a button, consider the integration with [Toggl](../time-and-costs/time-tracking/toggl-integration/).

## Frequently asked questions - FAQ

### Is there an integration with Outlook?

No, we don't have an outlook integration. Nevertheless, you can define incoming emails to OpenProject to get converted into tasks. Also, you can configure the email notifications sent by OpenProject to the project members. More information can be found [here](../../system-admin-guide/email/#email-settings).

### Is there an integration with OneNote?

No, there isn't.