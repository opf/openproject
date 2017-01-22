import {WorkPackageTable} from '../../wp-fast-table';
import {States} from '../../../states.service';
import {WorkPackageResource} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {cellClassName} from '../../builders/cell-builder';
import {TableEventHandler} from '../table-events-registry';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';

export class CellClickHandler implements TableEventHandler {
  public states:States;

  constructor() {
    injectorBridge(this);
  }

  public get EVENT() {
    return 'click.table.cell';
  }

  public get SELECTOR() {
    return `.${cellClassName}`;
  }

  protected workPackage:WorkPackageResource;

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    console.log('CLICK!');

    // Mark row as being edited
    // row.classList.add('-editing');

  }
}

CellClickHandler.$inject = ['states'];
