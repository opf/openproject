---
sidebar_navigation:
  title: Changing to BIM Edition
  priority: 100
---

# Changing to BIM Edition

An existing OpenProject on-premises (self hosted) installation can easily be switched to the BIM Edition.
The BIM Edition extends the capabilities of a normal OpenProject installation with special features
for the construction industry.

Switching to the BIM Edition will not affect your existing data. Your team will be able to continue 
working just as before. By switching to the BIM edition additional features will become available
when you activate the "BCF" module a project's settings.

## Instructions

### Backup and upgrade

First, backup your data and update your installation to the latest OpenProject version as described in [Upgrading](../operation/upgrading).

### Switching to BIM Edition

Now that your OpenProject instance is up to date, you can _reconfigure_ it to be a BIM Edition.

On the command line of your server run the following command. It will open a wizard that
guides you through through the most important installation settings of your instance.
On the first screen it will ask you to select the edition. Please select _bim_ and click _next_.
You can keep the screens that follow just as they are. You don't need to change any setting. 
Your current settings will be preselected for you. You can simply click "next" in every step 
until the end of the wizard. Finally, this will also
trigger the installation of the necessary libraries and tools for 3D model conversion.

`sudo openproject reconfigure`

Congratulations, you've successfully switched to the BIM Edition. However, for the best
experience you might consider also the next configuration.

You can check that all tools for the IFC model conversion were installed by going to
_-> Administration -> Information_ and check that _IFC conversion pipeline available_ 
has a check icon (✓) to the right.

### Activating the BCF module per default for every new project (optional)

You can enable the BCF module per default for all new projects in the future.

Go to _-> Administration -> System settings -> Projects_ and within the section 
_Settings for new projects_ activate the checkbox for _BCF_.

### Add typical work package types and statuses for BCF management (optional)

For BCF management process you might want to add special work package types to your
installation.

In freshly created OpenProject BIM instances those types are already present. However,
as you have just switched from a normal OpenProject installation you will need to create
those work package types by hand. Please find detailed instructions on how to add work 
package types in [Manage Work Package Types](../../system-admin-guide/manage-work-packages/work-package-types/).

You might consider adding the following typical work package types:

- Issue (color `indigo-7`)
- Clash (color `red-8`)
- Remark (color `GREEN (DARK)`)
- Request (color `cyan-7`)

We recommend that each type has the following status options:

- New (color `blue-6`)
- In progress (color `orange-6`)
- Resolved (color `'green-3`)
- Closed (color `'gray-3`)

### Activating the "OpenProject BIM" theme (optional)

OpenProject installations with a valid Enterprise Edition token can switch to the BIM 
theme.

Go to _-> Administration -> Design_ and from the _Themes_ drop down menu choose _OpenProject BIM_.

## Frequently asked questions - FAQ

### How can I select the BIM edition during installation?

Please have a look at the [initial configuration instruction](../installation/packaged/#step-1-select-your-openproject-edition).

### Can I use OpenProject BIM for free, too?

Yes, (only) as part of the Community Edition you can use OpenProject BIM for free. Please have a look [here](#switching-to-bim-edition) to find out how to activate the BIM modules in your on-premises installation.

### How can I find out more about OpenProject BIM edition?

Please have a look at our [demo video](https://www.youtube.com/watch?v=ThA4_17yedg) and at our [website](https://www.openproject.org/bim-project-management/). You can start a free trial there, too.

### Which IFC format are you using for conversion in the BIM module?

IFC2x3 and IFC4. We accept those formats and convert them to some other format that is optimized for web.

