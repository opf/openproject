import {CardClickHandler} from "core-components/wp-card-view/event-handler/click-handler";

export class BcfClickHandler extends CardClickHandler {

  protected handleWorkPackage(wpId:any, element:JQuery<HTMLElement>, evt:JQuery.TriggeredEvent) {
    this.setSelection(wpId, element, evt);

    // Open the viewpoint if any
    // ...
  }

}
