---
sidebar_navigation:
  title: Integrations
  priority: 400
description: Integration to OpenProject.
keywords: projects, integration, Jira
---
# Integrations and Community plugins

There are various integrations and Community plugins out there. Please [contact us](https://www.openproject.org/contact/) if you want to have your plugin to be added to this list.

If you have previously worked with other tools and want to switch or need an integration to OpenProject, there is a way to do so for some applications.

## OpenProject integrations

OpenProject offers integrations with a variety of tools to streamline your workflows and extend platform capabilities. These integrations are maintained and supported by the OpenProject team to ensure compatibility and stability.

### GitHub

OpenProject offers a basic GitHub integration. You will find more information about the GitHub integration in our [GitHub integration guideline](./github-integration/).

### GitLab

OpenProject offers a GitLab integration, based on the [GitLab plugin contributed by the Community](https://github.com/btey/openproject-gitlab-integration). More information on the GitLab integration is available in our [GitLab integration guide](./gitlab-integration/).

### XWiki

[feature: xwiki_integration ]

OpenProject offers integration with XWiki for wiki collaboration. You can find more information
about [setting up the integration with XWiki](./xwiki) and [using the integration](../../user-guide/work-packages/edit-work-package/#link-to-or-create-a-wiki-page).

### Nextcloud

OpenProject offers integration with Nextcloud for file storage and collaboration. You can find more information about [setting up the integration with Nextcloud](./nextcloud) and [using the integration](../../user-guide/file-management/nextcloud-integration/).

[feature: one_drive_sharepoint_file_storage]

> [!NOTE]
> This feature includes using both OneDrive and SharePoint integrations.

### OneDrive (Enterprise add-on)

OpenProject offers an integration with OneDrive for file storage and collaboration. You can find more information about [setting up the integration with OneDrive](./one-drive) and [using the integration](../../user-guide/file-management/one-drive-integration/).


### SharePoint (Enterprise add-on)

OpenProject offers an integration with SharePoint for file storage and collaboration. You can find more information about [setting up the integration with SharePoint](./share-point) and [using the integration](../../user-guide/file-management/sharepoint-integration/).



## Community plugins

Community plugins are developed and maintained by third parties or community contributors.

> [!IMPORTANT]
> We do not guarantee error-free and seamless use of the Community plugins. Installation and use is at your own risk. If you have any questions, issues, or feedback, please contact the respective plugin developers directly.

### Mattermost

There is a user-provided integration with Mattermost. Please note that it is not officially supported and that we do not take any liability when you use it. You can find it [here](https://github.com/girish17/op-mattermost).

### SL2OP 

SL2OP is an integration between SelectLine ERP and OpenProject. Please note that it was developed and is maintained by DAKO-IT, we do not provide any support for it. You can find more information [here](https://dako-it.com/captain-finn-software-fuer-selectline/schnittstelle-openproject-fuer-selectline/detail/80).

> [!NOTE]
> It is currently only available in German. 

### Slack

There is a rudimentary OpenProject Slack integration from the community. It messages a configured Slack channel, every time a Work Package or Wiki site is modified. This integration is not officially supported by OpenProject.
To activate it in the Enterprise cloud please [get in touch](https://www.openproject.org/contact/). For the Enterprise on-premises edition and the Community edition you can find the plugin and its documentation on GitHub: [OpenProject Slack plugin](https://github.com/opf/openproject-slack)

### Testuff

There is an OpenProject integration with Testuff. Please note that it was developed directly by Testuff and we do not provide any support for it. You can find it [here](https://testuff.com/product/help/openproject/).

### Thunderbird

There is an OpenProject integration with Thunderbird from the Community. Please note that this add-on is not officially supported and that we do not take any liability when you use it. You can find it [here](https://addons.thunderbird.net/en-GB/thunderbird/addon/thunderbird-openproject/).

### TimeCamp

There is an integration between OpenProject and TimeCamp. We provide a [short instruction](../../user-guide/time-and-costs/time-tracking/timecamp-integration/) how to set it up and use it. However, please note that this add-on is not officially supported and we do not take any liability when you use it.

### Time Tracker for OpenProject

[Time Tracker](https://open-time-tracker.com/) is a mobile app that records time spent on tasks and logs it to your OpenProject instance. We provide a [short instruction](../../user-guide/time-and-costs/time-tracking/time-tracker-integration/) how to set it up and use it.  Please keep in mind that it is not developed by OpenProject and is not supported by us.

### Toggl

We do offer an integration between OpenProject and the time tracking app Toggl. Find out more [here](../../user-guide/time-and-costs/time-tracking/toggl-integration/).

## Other tools and workarounds

Some tools do not have a direct integration with OpenProject, but there are workarounds or alternative methods to use them alongside OpenProject. These may involve manual steps, third-party services, or custom setups.

> [!IMPORTANT]
> These tools are not officially integrated with OpenProject. We do not guarantee full compatibility or error-free usage. Use of these workarounds is at your own risk. 

### Excel

Find out more about the [Excel synchronization with OpenProject](./excel-synchronization).

### JIRA

We do not provide a direct integration between OpenProject and JIRA ourselves. 

If you want to migrate from JIRA to OpenProject, there are several ways to do that, including OpenProject [API](../../api/), OpenProject [Excel sync](excel-synchronization) or using a [Markdown export app](https://marketplace.atlassian.com/apps/1221351/markdown-exporter-for-confluence). 

Keep in mind that we are [developing a dedicated OpenProject migration solution](https://community.openproject.org/projects/jira-migration). In the meantime our partners at [ALM Toolbox](https://www.almtoolbox.com/) are happy to support you with Jira or Confluence migration. 

Please consult [JIRA migration overview page](../../installation-and-operations/jira-migration/) for an in-depth overview of all existing options.

### Microsoft Project

To move tasks from MS Project to OpenProject, you can export your MS Project file to Excel and then [synchronize it with OpenProject]( ./excel-synchronization/).

### Timesheet

Currently, there is no direct integration between OpenProject and Timesheet. If you are looking for a time tracking tool with a simple push of a button, consider the integration with [Toggl](../../user-guide/time-and-costs/time-tracking/toggl-integration/).

### Trello

Currently, there is no direct integration between OpenProject and Trello. To synchronize tasks from Trello to OpenProject, export your tasks from Trello into an Excel file and then import these tasks via an [Excel plugin into OpenProject](./excel-synchronization).

If you would like to learn more about OpenProject's features vs Trello, please read [here](https://www.openproject.org/blog/trello-alternative/).
