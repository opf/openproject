---
sidebar_navigation:
  title: Using Stimulus
description: An introduction of how we use Stimulus to sprinkle interactivity
keywords: Stimulus, Ruby on Rails, Hotwire
---

# Using Stimulus

In a decision to move OpenProject towards the [Hotwire approach](https://hotwired.dev/), we introduced [Stimulus.js](https://stimulus.hotwired.dev) to replace a collection of dynamically loaded custom JavaScript files used to sprinkle some interactivity.

This guide will outline how to add controllers and the conventions around it. This is _not_ a documentation of stimulus itself. Use their [documentation](https://stimulus.hotwired.dev) instead.

## Adding controllers

All controllers live under `frontend/src/stimulus/controllers/`. The naming convention is `<controller-name>.controller.ts`, meaning to dasherize the name of the controller. This makes it easier to generate names and classes using common IDEs.

If you want to add a common pattern, manually register the controller in `frontend/src/stimulus/setup.ts` with a `preregister` call, e.g., `OpenProjectStimulusApplication.preregister('flash', FlashController);`. Often you'll want to have a dynamically loaded controller instead though.

### Adding a static controller from a plugin

If you want to add a stimulus controller from plugin code, you can do so by manually adding it to the preregister:

```typescript
import { OpenProjectStimulusApplication } from 'core-stimulus/openproject-stimulus-application';
import { MyTestControllerClass } from './test/foo/my-test.controller';

OpenProjectStimulusApplication.preregister(
  'test',
  MyTestControllerClass
);
```

### Dynamically loaded controllers

To dynamically load a controller, it needs to live under `frontend/src/stimulus/controllers/dynamic/<controller-name>.controller.ts`.
The application controller (`frontend/src/stimulus/controllers/op-application.controller.ts`) will automatically load controllers dynamically if they are not registered in the `setup.ts` file.

```html
<div data-controller="users"></div>
```

#### Namespacing dynamic controllers

If you want to organize your dynamic controllers in a subfolder, use the [double dash convention](https://stimulus.hotwired.dev/handbook/installing#controller-filenames-map-to-identifiers) of stimulus. For example, adding a new admin controller `settings`, you'd do the following:

1. Add the controller under `frontend/src/stimulus/controllers/dynamic/admin/settings.controller.ts`
2. Specify the controller name with a double dash for each folder

```html
<div data-controller="admin--settings"></div>
```

You need to take care to prefix all actions, values etc. with the exact same pattern, e.g., `data-admin--settings-target="foobar"`.

#### Dynamically loading controllers from plugins

If you want to add a dynamic stimulus controller import from plugin code, you can do so by manually adding it to the preregister:

```typescript
import { OpenProjectStimulusApplication } from 'core-stimulus/openproject-stimulus-application';

OpenProjectStimulusApplication.preregisterDynamic(
  'test',
  () => import('./test.controller')
);
```

This ensures that the controller is loaded only when it is needed, and not at application startup. The controller will then be enabled when the `data-controller` attribute is present in the DOM through the same mechanism as for the core dynamic controllers.

### Requiring a page controller

If you have a single controller used in a partial, we have added a helper to use in a partial in order to append a controller to the `#content-wrapper` tag. This is useful if your template doesn't have a single DOM root. For example, to load the dynamic `project-storage-form` controller and provide a custom value to it:

```erb
<% content_controller 'project-storage-form',
                      'project-storage-form-folder-mode-value': @project_storage.project_folder_mode %>
```

Similarly, `body_controller 'name'` adds a controller to the `<body>` tag.

## Conventions

- **Angular services:** to use Angular services such as the `TurboRequestsService` from a controller, use the [`useAngularServices`](https://github.com/opf/openproject/blob/dev/frontend/src/stimulus/mixins/use-angular-services.ts) mixin instead of calling `window.OpenProject.getPluginContext()` yourself. See [requesting turbo-streams within Stimulus controllers](../hotwire-view-components/#requesting-turbo-streams-within-stimulus-controllers) for an example.
- **Element lookups:** `@openproject/stimulus-elements` is installed in `setup.ts` and allows declaring lookups of custom elements with `static elements`, e.g., `static elements = { menu: 'action-menu' };` together with `declare readonly menuElement:ActionMenuElement;`.
- **Tests:** controller specs live next to the controller as `<controller-name>.controller.spec.ts`. The helpers in `frontend/src/stimulus/test-helpers.ts` are described in the [frontend testing guide](https://github.com/opf/openproject/blob/dev/frontend/doc/TESTING.md).
