// Need to re-use this from typings of the actual context if at all possible
import {openprojectLegacyModule} from "core-app/openproject-legacy-app";
import {IPluginContext} from "../../typings/open-project-legacy.typings";

export class PluginContextService {
  public context?:IPluginContext;

  constructor() {
    window.OpenProject.getPluginContext().then((context:IPluginContext) => this.context = context!);
  }

  public getContext():Promise<IPluginContext> {
    return (window as any).OpenProject.getPluginContext();
  }
}

openprojectLegacyModule.service('pluginContext', PluginContextService);
