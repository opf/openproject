import {Injector} from "@angular/core";
import {OpenProjectPluginContext} from "core-app/modules/plugins/plugin-context";
import {debugLog} from "core-app/helpers/debug_output";

/**
 * Create a plugin context to be used by other plugins and modules on the OP domain.
 *
 * @param {Injector} injector
 */
export function initializePluginContext(injector:Injector) {
  return () => {
    debugLog("Registering OpenProject plugin context");
    window.OpenProject.pluginContext.putValue(new OpenProjectPluginContext(injector));
  };
}
