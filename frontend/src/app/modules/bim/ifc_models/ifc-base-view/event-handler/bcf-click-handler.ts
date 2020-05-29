import {CardClickHandler} from "core-components/wp-card-view/event-handler/click-handler";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {States} from "core-components/states.service";
import {IFCViewerService} from "core-app/modules/bim/ifc_models/ifc-viewer/ifc-viewer.service";
import {BcfApiService} from "core-app/modules/bim/bcf/api/bcf-api.service";
import {BcfViewpointPaths} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.paths";

export class BcfClickHandler extends CardClickHandler {
  @InjectField() viewer:IFCViewerService;
  @InjectField() states:States;
  @InjectField() bcfApi:BcfApiService;

  protected handleWorkPackage(wpId:string, element:JQuery<HTMLElement>, evt:JQuery.TriggeredEvent) {
    this.setSelection(wpId, element, evt);
    const wp = this.states.workPackages.get(wpId).value!;

    // Open the viewpoint if any
    if (this.viewer.viewerVisible() && wp.bcfViewpoints) {
      this.viewer.showViewpoint(wp, 0);
    }
  }
}