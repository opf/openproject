---

sidebar_navigation:
  title: Automations
  priority: 100
description: Intelligent workflows with automated actions.
keywords: automations, automations, automated workflow
---

# Work package automations (Enterprise add-on)

Automated workflows with automations support you to easily update several work package attributes at once with a single click on one button.

You can use automations to standardize your workflows, avoid errors and reduce manual work for updates.

[feature: custom_actions ]

Watch the following video to see how you can configure your automations:

![Video](https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-Custom-Actions.mp4)

## Create automations

Navigate to **Administration → Work packages → Automations**.

To create an automation, click **+ Automation**.

![automations overview in OpenProject administration](openproject_system_guide_work_packages_custom_actions_overview.png)

You can now configure the **Conditions** and **Actions** for the automation.

1. Enter a **name** for the automation button. This name will then appear on the button on the work package.
2. Set a **description** (i.e. what are the conditions and actions).
3. Set the **conditions** for which the automation button should apply, e.g. in which status, for which role, what type or in which project should the automation button appear.
4. Set the **actions** what should happen after pressing the automation button, e.g. status transitions, and changes to any other attribute.
5. **Save** your changes.

![Create a new automation in OpenProject administration](openproject_system_guide_work_packages_custom_actions_create_new.png)

If a work package is then in the defined condition, the button will appear on top of a work package and will apply the actions and changing the attributes of a work package as defined in the configuration when clicking on the button.

![Automation button in an OpenProject work package](openproject_system_guide_work_packages_custom_actions_button.png)

## Update, sort or delete automations

1. Click on the name of a automation or on the pencil icon in order to update the attributes.
2. Click the arrow icons in order to sort the order of the automation button on the work packages.
3. Delete a automation.

![Update or delete automations in OpenProject administration](openproject_system_guide_work_packages_custom_actions_edit_delete.png)

> [!TIP]
>
> Read this [blog article](https://www.openproject.org/blog/custom-action-self-assign/) for an example of automations used within OpenProject team to quickly self-assign a work package.
