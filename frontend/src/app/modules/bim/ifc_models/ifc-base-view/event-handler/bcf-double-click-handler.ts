import {StateService} from "@uirouter/core";
import {CardDblClickHandler} from "core-components/wp-card-view/event-handler/double-click-handler";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class BcfDoubleClickHandler extends CardDblClickHandler {
  @InjectField() state:StateService;

  protected handleWorkPackage(wpId:string) {
    this.state.go('.details', { workPackageId: wpId });
  }
}
