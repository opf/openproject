import { TableEventComponent } from 'core-app/features/work-packages/components/wp-fast-table/handlers/table-handler-registry';
import { WorkPackageTable } from '../wp-fast-table';

/**
 * Execute the callback if the given Event is either an ENTER key or a click
 */
export function onClickOrEnter(evt:Event, callback:() => void) {
  if (evt.type === 'click' || (evt.type === 'keydown' && (evt as KeyboardEvent).key === 'Enter')) {
    callback();
  }
}

export abstract class ClickOrEnterHandler {
  public handleEvent(view:TableEventComponent, evt:MouseEvent|KeyboardEvent) {
    onClickOrEnter(evt, () => this.processEvent(view.workPackageTable, evt));
  }

  protected abstract processEvent(table:WorkPackageTable, evt:MouseEvent|KeyboardEvent):void;
}
