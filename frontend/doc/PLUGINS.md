Rails plugins with Frontends
====================

Some OpenProject modules ship a frontend of their own. Costs is the worked example below; it lives in this repository at `modules/costs` and is loaded from `Gemfile.modules`, not cloned separately.

For developing these plugins, they need to be linked so either the Legacy or Angular frontend can see and process them.



## Installing a Plugin



Modules bundled with OpenProject are already listed in `Gemfile.modules` and need no installation step:

```ruby
gem 'costs', path: 'modules/costs'
```

A plugin developed outside this repository is added to `Gemfile.plugins` instead, pointing at wherever you cloned it:

```ruby
group :opf_plugins do
  gem 'openproject-my-plugin', path: '../plugins/openproject-my-plugin'
end
```

After changing either file, run `bundle install`.

The plugin is now known in the OpenProject application, but their frontends are not linked. For development, before you run any frontend build or `CLI` commands, execute this rake task:



```
./bin/rake openproject:plugins:register_frontend
```



This will ensure those plugins with a frontend are symlinked to `frontend/src/app/features/plugins/linked/` for plugins with an exported Angular module under `frontend/module/main.ts`.



### Example: the Costs module

The Costs module (`modules/costs`) has both legacy components that are still used by Rails templates as well as an entry module file to register to the Angular frontend.

Let's take a look at the file structure of the costs folder `frontend/`:

```
module
├── main.ts
└── wp-display
    ├── costs-by-type-display-field.module.ts
    └── currency-display-field.module.ts
```

The Angular frontend entry point is `frontend/module/main.ts` and should export a `PluginModule` ngModule that looks like the following:

```typescript
import { NgModule } from '@angular/core';
import { OpenProjectPluginContext } from 'core-app/features/plugins/plugin-context';
import { WorkPackageAction } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';

export function initializeCostsPlugin() {
  window.OpenProject.getPluginContext()
    .then((pluginContext:OpenProjectPluginContext) => {
      // Register a field type to the core EditField functionality
      pluginContext.services.editField.extendFieldType('select', ['Budget']);

      // Register a hook callback for a specific core hook
      pluginContext.hooks.workPackageSingleContextMenu(():WorkPackageAction => ({
        key: 'log_costs',
        icon: 'icon-projects',
        indexBy: (actions:WorkPackageAction[]) => {
          const index = actions.findIndex((action) => action.key === 'log_time');
          return index !== -1 ? index + 1 : actions.length;
        },
        link: 'logCosts',
      }));
    });
}

@NgModule({
  providers: [],
})
export class PluginModule { // The name PluginModule is important!
  constructor() {
    initializeCostsPlugin();
  }
}
```

`workPackageSingleContextMenu` is invoked without arguments, so its callback takes none. `indexBy`
receives the actions collected so far and returns the position the new entry should take.

`hooks` is typed as `Record<string, (callback:(...args:any[]) => unknown) => void>`, so a callback
returning anything at all compiles. Annotating the return as `WorkPackageAction` is what makes a
wrong key an error rather than a silent no-op — the consuming code casts the collected results to
`WorkPackageAction[]` regardless.

A working implementation of this pattern lives at `modules/costs/frontend/module/main.ts`.

The rake task will generate a module under `frontend/src/app/features/plugins/linked-plugins.module.ts` that will import all these plugin modules. This happens by filling an ERB template by the rake task and is performed in `lib/open_project/plugins/frontend_linking/*` 
