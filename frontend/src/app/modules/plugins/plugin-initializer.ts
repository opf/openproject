import {Injector} from "@angular/core";
import {OpenProjectPluginContext} from "core-app/modules/plugins/plugin-context";
import {debugLog} from "core-app/helpers/debug_output";
import {registeredPlugins} from "core-app/modules/plugins/registered-plugins";
import {PluginInitializer} from "core-app/modules/plugins/plugin-initializer.type";

/**
 * Create a plugin context to be used by other plugins and modules on the OP domain.
 *
 * @param {Injector} injector
 */
export function initializePlugins(injector:Injector) {
  return () => {
    debugLog("Registering OpenProject plugin context");
    const pluginContext = new OpenProjectPluginContext(injector);
    window.OpenProject.pluginContext.putValue(pluginContext);

    registeredPlugins.forEach((initializer:PluginInitializer) => {
      initializer.load(injector, pluginContext);
    });
  };
}
