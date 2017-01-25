import {keyCodes} from '../../common/keycode.enum';
import {WorkPackageTable} from '../wp-fast-table';

export abstract class ClickOrEnterHandler {
  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    if (evt.type === 'click' || (evt.type === 'keydown' && evt.which === keyCodes.ENTER)) {
      this.processEvent(table, evt);
    }
  }

  protected abstract processEvent(table:WorkPackageTable, evt:JQueryEventObject);
}
