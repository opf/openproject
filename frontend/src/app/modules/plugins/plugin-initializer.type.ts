import {Injector} from "@angular/core";
import {OpenProjectPluginContext} from "core-app/modules/plugins/plugin-context";

export interface PluginInitializer {
  name:string;
  load(injector:Injector, pluginContext:OpenProjectPluginContext):void;
}
