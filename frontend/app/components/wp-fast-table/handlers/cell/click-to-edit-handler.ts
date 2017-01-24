import {cellClassName, editableClassName} from '../../builders/cell-builder';
import {TableEventHandler} from '../table-events-registry';
import {BaseCellEditHandler} from './base-edit-handler';

export class CellClickHandler extends BaseCellEditHandler implements TableEventHandler {

  public get EVENT() {
    return 'click.table.cell';
  }

  public get SELECTOR() {
    return `.${cellClassName}.${editableClassName}`;
  }
}
