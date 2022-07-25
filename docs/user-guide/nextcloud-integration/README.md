---
sidebar_navigation:
  title: Nextcloud integration
  priority: 600
description: Nextcloud integration
keywords: integrations, apps, Nextcloud

---

# Nextcloud integration

[Nextcloud](https://nextcloud.com/), the world’s most-deployed on-premises collaborative file storage platform and [OpenProject](https://www.openproject.org/), the leading free and open source project management and collaboration software, join forces. **Data sovereignty** and **open source** are core values that are important to both OpenProject and Nextcloud and which firn the foundational common ground for this integration.

This collaboration allows the users to link files and folders in Nextcloud with work packages in OpenProject. Users can now can see all files related to a work package and all work packages related to a file. Project members no longer need to lose time time trying to find the right files to be able to complete their tasks, and the intergatino of OpenProject-specific notifications on Nextcloud dashboard ensures that no change goes unnoticed. Users are also now able to find linked work packages directly in Nextcloud. 

The integration is available starting with Nextcloud 22 and OpenProject 12.2. To be able to use this integration, the administrator of your instance should have completed the [Nextcloud integration setup](../../system-admin-guide/integrations/nextcloud).

## Benefits of the integration

The integration enables users to perform multiple actions in both Nextcloud and OpenProject:

- Link their Nextcloud files to OpenProject work packages via the Nextcloud interface
- Check which work packages are related to any file in Nextcloud
- Keep an eye on ongoing project activities directly via their Nextcloud instance
- Have a clear list view of the files linked to a specific work package in OpenProject
- Have great control of content to avoid risk of non-compliance or data leaks

## How can I use this integration?

As a user of both Nextcloud and OpenProject, you can benefit from this integration in both platforms:

- **In OpenProject:**
  The Files tab lets you see regular attachments to a work package but now also lists files that had been linked from Nextcloud to OpenProject. You can use secondary actions available with each file to directly open it, download it, show the containing folder in Nextcloud or remove the link.
  ![Empty_status_files](1_0_00-No_files_linked.png)

  ![OP_linked_files](1_1_00-All_files_available.png)

  **IMPORTANT NOTE:** In this version of the integration, linking Nextcloud files via OpenProject is not possible. This will be possible in the near future.

  - **In Nextcloud:**
    You will be able to access the OpenProject tab in Nextcloud by accessing the details split screen of any file. In this tab, you will be able to search for the work package to which you would like to link the current file. Once a work package is linked to a file, you can always unlink it  by clicking on the **unlink** icon.

    ![NC_search_WP](0_0_00-File_Relation_Search.png)

    ![NC_linked_WP](0_1_01-File_WP_Actions.png)

    
    In addition to actions related to the file itself, you can also display the OpenProject widge in the Nextcloud dashboard in order to keep an eye on the the latest changes and updates to your work packages:
    ![add_NC_widget](Add_OpenProject_widget-0ea8c054.png)

    ![added_NC_widget](Nextcloud_dashboard-c04681eb.png)

    Additionally, you can activate three extra features for your Nextcloud and OpenProject integration via your personal settings under 'Connected accounts': **Enable navigation link** to display a link to your OpenProject instance in the header navigation, **Enable unified search for tickets** to include OpenProject information in the the built-in universal search and **Enable notifications for activity in my work packages** to receive Nextcloud notifications in your OpenProject work packages.

    ![NC_extra_settings](Nextcloud_connected_account-b9ffa0e3.png)

    ![NC_extra_navlink](Navigation_link_OpenProject-0fc98e3b.png)

    ![NC_extra_search](Unified_search-73e2dc96.png)


## **Next steps for the integration**

Further integration efforts are under way. In the near future, users will be able to linking and upload files to Nextcloud directly from OpenProject.

## Possible errors and troubleshooting

- **OpenProject - No permissions to see the file:** If the user doesn't have permissions to see the details of a file or to open some of the files linked to this work packages (due to permissions, they will be able to see the name, time of last modification and the name of the modifier but will _not_ be able to perform any further actions. To open or access such files, they will need to contact the Nextcloud administrator or the creator of the file so that they can provide the necessary actions.
  ![OP_no_permissions](1_1_01-Not_all_files_available.png)

- **OpenProject - User not logged in to Nextcloud:** If the user is not logged in to Nextcloud, they might see this error. They will still be able to see the list of files linked to the work package but not perform any actions. The user may simple log in to their Nextcloud instance to be restore full functionality.
  ![OP_login_error](1_0_01-Log_in_error.png)

- **OpenProject - Connection error:** This error is displayed when there is a technical error with the connection and OpenProject is unable to connect to Nextcloud. Users should contact the instance administrator to identify and to resolve the issue.
  ![OP_connection_error](1_0_02-Connection_broken.png)

- **OpenProject - Files fetching error:** In rare ocassions, it is possible for the integration to not be able to fetch all the details of the files linked to the work package. A simple page refresh should solve the issue. if the error persist, they should contact instance administrator.

  ![OP_fetching_error](1_0_03-Fetching_error.png)

- **Nextcloud - Connection error:** This is displayed when there is a error with the connection between the two platforms that is not allowing Nextcloud to connect to OpenProject. Users should contact their instance administrator to try to identify and resolve the problem.**
  ![NC_connection_error](0_2_00-Connection_error.png)

- **Nextcloud - Project notifications are not displayed:** Please ensure that _Cron_ is activated in the background jobs section of Nextcloud basic settings.
  ![NC_notifications_not_displayed](Cron_job_settings-ad025bc2.png)
