import { keyCodes } from 'core-app/modules/common/keyCodes.enum';
import { WorkPackageTable } from "../wp-fast-table";
import { TableEventComponent } from "core-components/wp-fast-table/handlers/table-handler-registry";


/**
 * Execute the callback if the given JQuery Event is either an ENTER key or a click
 */
export function onClickOrEnter(evt:JQuery.TriggeredEvent, callback:() => void) {
  if (evt.type === 'click' || (evt.type === 'keydown' && evt.which === keyCodes.ENTER)) {
    callback();
    return false;
  }

  return true;
}


export abstract class ClickOrEnterHandler {
  public handleEvent(view:TableEventComponent, evt:JQuery.TriggeredEvent) {
    onClickOrEnter(evt, () => this.processEvent(view.workPackageTable, evt));
  }

  protected abstract processEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent):boolean;
}
