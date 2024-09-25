---
sidebar_navigation:
  title: Using Stimulus
description: An introduction of how we use Stimulus to sprinkle interactivity
keywords: Stimulus, Ruby on Rail, Hotwire
---



# Using  Stimulus

In a decision to move OpenProject towards the [Hotwire approach](https://hotwired.dev/), we introduced [Stimulus.js](https://stimulus.hotwired.dev) to replace a collection of dynamically loaded custom JavaScript files used to sprinkle some interactivity.

This guide will outline how to add controllers and the conventions around it. This is _not_ a documentation of stimulus itself. Use their documentation instead: https://stimulus.hotwired.dev

## Adding controllers

All controllers live under `frontend/src/stimulus/controllers/`. The naming convention is `<controller-name>.controller.ts`, meaning to dasherize the name of the controller. This makes it easier to generate names and classes using common IDEs.

If you want to add a common pattern, manually register the controller under `frontend/src/stimulus/setup.ts`. Often you'll want to have a dynamically loaded controller instead though.

### Dynamically loaded controllers

To dynamically load a controller, it needs to live under `frontend/src/stimulus/controllers/dynamic/<controller-name>.controller.ts`.

In DOM, you'll tell the application the controller is dynamically loaded using the `data-application-target="dynamic"`attribute. It tells the application controller (`frontend/src/stimulus/controllers/op-application.controller.ts`) we load on every page on body to dynamically import and load the controller named `users`.

```html
<div data-controller="users" data-application-target="dynamic"></div>
```

#### Namespacing dynamic controllers

If you want to organize your dynamic controllers in a subfolder, use the [double dash convention](https://stimulus.hotwired.dev/handbook/installing#controller-filenames-map-to-identifiers) of stimulus. For example, adding a new admin controller `settings`, you'd do the following:

1. Add the controller under `frontend/src/stimulus/controllers/dynamic/admin/settings.controller.ts`
2. Specify the controller name with a double dash for each folder

```html
<div data-controller="admin--settings" data-application-target="dynamic"></div>
```

You need to take care to prefix all actions, values etc. with the exact same pattern, e.g., `data-admin--settings-target="foobar"`.

### Requiring a page controller

If you have a single controller used in a partial, we have added a helper to use in a partial in order to append a controller to the `#content-wrapper` tag. This is useful if your template doesn't have a single DOM root. For example, to load the dynamic `project-storage-form` controller and provide a custom value to it:

```erb
<% content_controller 'project-storage-form',
                      dynamic: true,
                      'project-storage-form-folder-mode-value': @project_storage.project_folder_mode %>
```
