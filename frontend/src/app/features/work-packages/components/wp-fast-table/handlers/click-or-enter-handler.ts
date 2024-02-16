import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { TableEventComponent } from 'core-app/features/work-packages/components/wp-fast-table/handlers/table-handler-registry';
import { WorkPackageTable } from '../wp-fast-table';

/**
 * Execute the callback if the given JQuery Event is either an ENTER key or a click
 */
export function onClickOrEnter(evt:JQuery.TriggeredEvent, callback:() => void) {
  if (evt.type === 'click' || (evt.type === 'keydown' && evt.which === KeyCodes.ENTER)) {
    callback();
  }
}

export abstract class ClickOrEnterHandler {
  public handleEvent(view:TableEventComponent, evt:JQuery.TriggeredEvent) {
    onClickOrEnter(evt, () => this.processEvent(view.workPackageTable, evt));
  }

  protected abstract processEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent):void;
}
