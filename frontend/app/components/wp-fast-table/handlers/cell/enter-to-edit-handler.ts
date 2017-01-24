import {cellClassName, editableClassName} from '../../builders/cell-builder';
import {TableEventHandler} from '../table-events-registry';
import {BaseCellEditHandler} from './base-edit-handler';
import {WorkPackageTable} from '../../wp-fast-table';
import {keyCodes} from '../../../common/keycode.enum';

export class EnterToEditHandler extends BaseCellEditHandler implements TableEventHandler {

  public get EVENT() {
    return 'keydown.table.cell';
  }

  public get SELECTOR() {
    return `.${cellClassName}.${editableClassName}`;
  }

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    if (evt.which === keyCodes.ENTER) {
      super.handleEvent(table, evt);
    }

    return false;
  }
}
