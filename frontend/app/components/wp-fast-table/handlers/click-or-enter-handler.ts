import {keyCodes} from "../../common/keyCodes.enum";
import {WorkPackageTable} from "../wp-fast-table";


/**
 * Execute the callback if the given JQuery Event is either an ENTER key or a click
 */
export function onClickOrEnter(evt:JQueryEventObject, callback:() => void) {
  if (evt.type === 'click' || (evt.type === 'keydown' && evt.which === keyCodes.ENTER)) {
    callback();
    return false;
  }

  return true;
}


export abstract class ClickOrEnterHandler {

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    onClickOrEnter(evt, () => this.processEvent(table, evt));
  }

  protected abstract processEvent(table:WorkPackageTable, evt:JQueryEventObject):boolean;
}
