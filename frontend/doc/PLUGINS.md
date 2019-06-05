Rails plugins with Frontends
====================

OpenProject Community Edition has some plugins that contain a frontend,
e.g., [Costs](https://github.com/finnlabs/openproject-costs/) or [My Project Page](https://github.com/finnlabs/openproject-my_project_page/).

For developing these plugins, they need to be linked so either the Legacy or Angular frontend can see and process them.



## Installing a Plugin



To install a plugin, you clone it locally and place it into your `Gemfile.plugins` like so:

```
group :opf_plugins do
  gem 'openproject-costs', path: '../plugins/openproject-costs'
end
```



After that you first need to bundle the application with `bundle install`.

The plugin is now known in the OpenProject application, but their frontends are not linked. For development, before you run any `webpack`  or `CLI` commands, execute this rake task:



```
./bin/rake openproject:plugins:register_frontend
```



This will ensure those plugins with a frontend are symlinked to one of the following locations:

1. `frontend/legacy/app/plugins/` for plugins with a `frontend/legacy-app`  folder.
2. `frontend/src/app/modules/plugins/linked/` for plugins with an exported Angular module under `frontend/module/main.ts`.



### Example: OpenProject Costs plugin

The [Costs](https://github.com/finnlabs/openproject-costs/) plugin has both legacy components that are still used by Rails templates as well as an entry module file to register to the Angular frontend.

Let's take a look at the file structure:

```
frontend/
├── legacy-app
│   └── components
│       ├── budget
│       │   ├── cost-budget-subform.directive.ts
│       │   └── cost-unit-subform.directive.ts
│       └── subform
│           └── cost-subform.directive.ts
└── module
    ├── main.ts
    └── wp-display
        ├── wp-display-costs-by-type-field.module.ts
        └── wp-display-currency-field.module.ts
```



Anything under `frontend/legacy-app/*` will be symlinked to the core and found by the legacy webpack build. Thus, it will be contained in the legacy bundle and can be accessed with the `activate_angular_js`  helper as described in the [legacy documentation](./LEGACY.md).



The Angular frontend entry point is `frontend/module/main.ts` and should export a `PluginModule` ngModule that looks like the following:

```typescript
export function initializeCostsPlugin() {
    return () => {
        window.OpenProject.getPluginContext()
            .then((pluginContext:OpenProjectPluginContext) => {
    		// Register a field type to the core EditField functionality
            pluginContext.services.editField.extendFieldType('select', ['Budget']);
	
            // Register a hook callback for a specific core hook
            pluginContext.hooks.workPackageSingleContextMenu(function(params:any) {
                return {
                    key: 'log_costs',
                    icon: 'icon-projects',
                    indexBy: function(actions:any) {
                        var index = _.findIndex(actions, {key: 'log_time'});
                        return index !== -1 ? index + 1 : actions.length;
                    },
                    resource: 'workPackage',
                    link: 'logCosts'
                };
            });
        });
    };
}


@NgModule({
    providers: [
        { provide: APP_INITIALIZER, useFactory: initializeCostsPlugin, deps: [Injector], multi: true },
    ],
})
export class PluginModule { // The name PluginModule is important!
}
```



The rake task will generate a Module under `frontend/src/app/modules/plugins/linked-plugin-module.ts` that will import all these plugin modules. This happens by filling an ERB template by the rake task and is performed in `lib/open_project/plugins/frontend_linking/*` 