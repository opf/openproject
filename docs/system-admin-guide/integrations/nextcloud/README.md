---
sidebar_navigation:
  title: Nextcloud integration setup
  priority: 600
description: Nextcloud integration setup
keywords: integrations, apps, Nextcloud
---

# OpenProject and Nextcloud integration setup 

The integration between OpenProject and Nextcloud has the potential to improve the productivity of all users. It combines the strengths of Nextcloud, the world’s most deployed on-premises collaborative file storage platform and OpenProject, the leading free and open source project management and collaboration software

This integration allows you to link files and folders in Nextcloud with work packages in OpenProject, allowing you to see all files related to a work package (in Open Project) and all work packages related to a file (in Nextcloud). As a project member, you no longer need to lose time trying to find the right files to be able to complete your tasks, and the integration of OpenProject-specific notifications on Nextcloud dashboard ensures that no change goes unnoticed. 

## Step-by-step setup instructions

For integrating with OpenProject 12.2, the minimum required version of Nextcloud is 22. For the desktop Nextcloud application, the minimum supported version is 2.0.0. To be able to configure this integration, you need to have administrator privileges in both your Nextcloud and OpenProject instances.

**1. Add the "OpenProject integration" app and connect the instance** - in Nextcloud

To activate your integration to OpenProject in Nextcloud, navigate to the built-in app store in the menu under your user name by clicking on _Your apps_. You can use the search field in the top right corner to look for the OpenProject integration app. Click the button **Download and enable**.

![Nextcloud_app_store](Nextcloud_app_store.png)

Once the OpenProject integration app is downloaded and enabled, you can access it from within the Settings page, via the the side menu. Start by entering the *host URL* of your desired OpenProject instance.

![Nextcloud_host](3_2_01 -NC_Step_1.png)

Click on the **Save** button and open your OpenProject instance in a new tab.

**2. Introduce the basic information of your integration** - in OpenProject

Make sure you are logged in as an administrator in your OpenProject instance. Navigate to *File storages* from the Administration page. To start configuring your new Nextcloud integration, click on the **Add (+)** button to add a new file storage.

![Storage_index](3_0_00-OP_OAuth_Empty_Index.png)

By default, the storage *provider type* is set to Nextcloud; this does not need to be modified. To proceed, enter a *name* to your Nextcloud storage. This will be visible to all the users using it. We highly recommended choosing a clear and distinct name that allows users to differentiate it from other potential file storages integrations in the future. You will also need to set the *Host URL* of your Nextcloud instance, including _https://_ bit of the address.

![Storage_basic_information](3_0_01-OP_General_Info.png)

Once you fill in the mandatory fields, click on the **Save and continue setup** button.

**3. Generate and copy the OpenProject OAuth values** - in OpenProject and Nextcloud

In this step, the *OpenProject OAuth values* are generated automatically. These values are needed to permit OpenProject to connect to Nextcloud. You will need to copy them from the Nextcloud integration window in a new tab (without exiting or closing your OpenProject tab) and pasting them in the respective fields under _OpenProject OAuth settings_.

> **Important**: The *OpenProjects OAuth values (client ID and client secret)* are not accessible again after you close the window. Please make sure you copy the generated values you see in the _Nextcloud OpenProject Integration settings_.

![OP_OAuth_values](3_1_00-OP_OAuth_application_details.png)

![Nextcloud_OP_OAuth_values](3_2_03-NC_Step_2.png)

Once you have copied the values, click on the **Save** button to proceed to the next step in Nextcloud.

**4. Generate and copy the Nextcloud OAuth values** - in Nextcloud and OpenProject

As in the previous step, the *OAuth values* are generated automatically, but this time on the Nextcloud end. These values are needed to allow the connection from Nextcloud to OpenProject, so you will need to once again copy them here and paste them in OpenProject (without closing the Nextcloud tab). If you had not clicked the **Done. Continue setup** button in the previous step, you can do so now to proceed to the screen where you will be able to paste the Nextcloud OAuth values in OpenProject.

![Nextcloud_NC_OAuth_values](3_2_04-NC_Step_3.png)

![OpenProject_NC_OAuth_values](3_3_01-OP_OAuth_application_details.png)

Once these values are entered, you can click the button **Save and complete setup** in your OpenProject tab and the **Yes, I have copied these values** in Nextcloud. Once this is done, your instance configuration is complete.

![OpenProject_success](3_4_00 - OAuth - OP Success.png)

![Nextcloud_success](3_2_05-NC_Success.png)

**5. Enable the file storages module and activate it in the desired project** - in OpenProject

Now that the integration setup is complete and ready to use, there is just one more step for you as administrator: you need to activate the *File storages* module and specify for which projects you would like to enable your new Nextcloud integration.

To activate the module, go to the **Project settings** in the desired project and access the **Modules** entry in the side menu. There, activate the *File storages* module. Once this is done, a new menu entry called **File storages** appears at the bottom of the side menu, where you can select your new Nextcloud integration.

![module_activation](Settings_modules.png)

![settings_files_storages](Settings_files_storages.png)

## How to reset your OAuth values

If you need to reset the values of the Nextcloud integration (as an administrator), you can always reset the OAuth values from both sides of the integration by clicking on the **Reset OAuth values** (in Nextcloud) or **Replace OAuth values** (in OpenProject) buttons.

> **Important**: When you reset/replace these values, you will need to update the configuration with the new OAuth credentials from the side you are reseting. This will also require all users to re-authorize OpenProject to access their Nextcloud account by logging in again.

![nextcloud_reset_OPOAuth](3_2_06 -NC_OP_OAuth_Replace.png)

![nextcloud_reset_NCOAuth](3_2_07-NC__OAuth_Replace.png)

![openproject_reset_OAuth](3_4_03-OP_Replace_Alert.png)


## How to delete a file storage integration

As an administrator, you can always delete the integration to Nextcloud using the **Delete** button in OpenProject settings or the **Reset** button in Nextcloud settings.

> **Important:** If you perform this action, the integration will be reset and deleted and all settings and user connections that were created will be deleted. This means that should you want to reconfigure the integration, you will need complete the entire setup process once again.
