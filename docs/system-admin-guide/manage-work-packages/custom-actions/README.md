---

sidebar_navigation:
  title: Custom actions
  priority: 950
description: Intelligent workflows with custom actions.
keywords: custom actions
---

# Automated workflows with custom actions (Enterprise add-on)

Automated workflows with custom actions support you to easily update several work package attributes at once with a single click on one button.

You can use custom actions to standardize your workflows, avoid errors and reduce manual work for updates.

> [!NOTE]
> The workflows with custom actions are an Enterprise add-on and only available for [Enterprise on-premises](https://www.openproject.org/enterprise-edition/) and [Enterprise cloud](https://www.openproject.org/enterprise-edition/#hosting-options) customers.

Watch the following video to see how you can configure your custom actions:

![Video](https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-Custom-Actions.mp4)

## Create custom actions

Navigate to the -> *Administration* -> *Work packages* -> *Custom actions*.

To create a new custom action button press the + Custom action** button.

![custom actions overview in OpenProject administration](openproject_system_guide_work_packages_custom_actions_overview.png)

You can now configure the **Conditions** and **Actions** for the custom action button.

1. Enter a **name** for the custom action button. This name will then appear on the button on the work package.
2. Set a **description** (i.e. what are the conditions and actions).
3. Set the **conditions** for which the custom action button should apply, e.g. in which status, for which role, what type or in which project should the custom action button appear.
4. Set the **actions** what should happen after pressing the custom action button, e.g. status transitions, and changes to any other attribute.
5. **Save** your changes.

![Create a new custom action in OpenProject administration](openproject_system_guide_work_packages_custom_actions_create_new.png)

If a work package is then in the defined condition, the button will appear on top of a work package and will apply the actions and changing the attributes of a work package as defined in the configuration when clicking on the button.

![Custom action button in an OpenProject work package](openproject_system_guide_work_packages_custom_actions_button.png)



## Update, sort or delete custom actions

1. Click on the name of a custom action or on the pencil icon in order to update the attributes.
2. Click the arrow icons in order to sort the order of the custom action button on the work packages.
3. Delete a custom action.

![Update or delete custom actions in OpenProject administration](openproject_system_guide_work_packages_custom_actions_edit_delete.png)

> [!TIP]
>
> Read this [blog article](https://www.openproject.org/blog/custom-action-self-assign/) for an example of custom actions used within OpenProject team to quickly self-assign a work package.
