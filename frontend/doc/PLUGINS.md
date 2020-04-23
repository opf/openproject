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



This will ensure those plugins with a frontend are symlinked to `frontend/src/app/modules/plugins/linked/` for plugins with an exported Angular module under `frontend/module/main.ts`.



### Example: OpenProject Costs plugin

The [Costs](https://github.com/finnlabs/openproject-costs/) plugin has both legacy components that are still used by Rails templates as well as an entry module file to register to the Angular frontend.

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
export function initializeCostsPlugin() {
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
}


@NgModule({
    providers: [
    ],
})
export class PluginModule { // The name PluginModule is important!
  constructor() {
    initializeCostsPlugin();
  }
}
```



The rake task will generate a Module under `frontend/src/app/modules/plugins/linked-plugin-module.ts` that will import all these plugin modules. This happens by filling an ERB template by the rake task and is performed in `lib/open_project/plugins/frontend_linking/*` 
