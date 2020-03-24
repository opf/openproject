---
sidebar_navigation:
  title: General settings
  priority: 990
description: General system settings in OpenProject.
robots: index, follow
keywords: general settings
---
# General system settings

You can configure general system settings in OpenProject. Under System settings on the tab **General** you can configure the following options.

1. **Application title**: This title will be displayed on the [application start page](../../../user-guide/start-page).

2. **Attachment maximum size** defines the maximum size of an attachment (for example in a work package).

3. **Object per page options** define the options of how many objects  (for example work packages or news entries) you can have displayed on one page. This is used for the pagination in the work package list. You can enter several values, separated by coma. Please note that the higher value you set, the more work packages will be initially loaded and therefore it might take longer time to load a work package page.

4. **Days displayed on project activity** determines how far back the project activities will be traced and displayed in the project's [Activity](../../../user-guide/activity).

5. **Host name**.

6. **Protocol**: HTTP, HTTPS.

7. **Cache formatted text** allows to save formatted text in cache, which will help load Wiki Pages faster.

8. **Enable feeds** – enables RSS feeds on wiki pages, forums and news via RSS client.

9. Set **feed content limit**.

10. **Max size of text files displayed inline** defines the maximum file size up to which different versions of a file are displayed next to each other when comparing (diff) two versions in a repository.

11. **Max number of diff lines displayed** defines the maximum number of lines displayed when comparing (diff) two versions in a repository.

12. **Display security badge** enables to display a badge with your installation status in the [Information administration panel](../../information), and on the [start page](../../../user-guide/start-page). It is displayed to administrators only.

    The badge will check your current OpenProject version against the official OpenProject release database to alert you of any updates or  known vulnerabilities. For more information on what the check provides,  what data is needed to provide available updates, and how to disable this check, please visit [the configuration documentation](../../information#security-badge).        

![System-admin-guide-system-settings-general](System-admin-guide-system-settings-general.png)

## Welcome block text

Create a welcome text block to display the most important information to users on your [application start page](../../../user-guide/start-page).

1. Insert a **welcome block title**.
2. Add the **welcome block text description**. You can add the same formatting options, as well as macros (work package lists etc.) as for the general text blocks.
3. Select to **display welcome block on homescreen** of the application.
4. Do not forget to **save** your changes.

![Sys-admin-general-welcome-text-block](Sys-admin-general-welcome-text-block.png)

