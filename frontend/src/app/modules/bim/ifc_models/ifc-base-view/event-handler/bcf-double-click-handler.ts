import {StateService} from "@uirouter/core";
import {CardDblClickHandler} from "core-components/wp-card-view/event-handler/double-click-handler";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {bimListViewIdentifier, BimViewService} from "core-app/modules/bim/ifc_models/pages/viewer/bim-view.service";

export class BcfDoubleClickHandler extends CardDblClickHandler {
  @InjectField() state:StateService;
  @InjectField() bimView:BimViewService;

  protected handleWorkPackage(wpId:string) {
    if (this.bimView.current === bimListViewIdentifier) {
      this.state.go('work-packages.show', { workPackageId: wpId });
    } else {
      this.state.go('.details', { workPackageId: wpId });
    }
  }
}
