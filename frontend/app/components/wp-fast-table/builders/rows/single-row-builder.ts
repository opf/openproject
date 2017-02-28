import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableRow} from '../../wp-table.interfaces';
import {States} from '../../../states.service';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {CellBuilder} from '../cell-builder';
import {DetailsLinkBuilder} from '../details-link-builder';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageResource} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {checkedClassName} from '../ui-state-link-builder';
import {rowId} from '../../helpers/wp-table-row-helpers';

export const rowClassName = 'wp-table--row';

export const internalColumnDetails = '__internal-detailsLink';

export class SingleRowBuilder {
  // Injections
  public states:States;
  public wpTableSelection:WorkPackageTableSelection;
  public I18n:op.I18n;

  // Cell builder instance
  protected cellBuilder = new CellBuilder();
  // Details Link builder
  protected detailsLinkBuilder = new DetailsLinkBuilder();

  constructor() {
    injectorBridge(this);
  }

  /**
   * Returns a shortcut to the current column state.
   * It is not responsible for subscribing to updates.
   */
  public get columns():string[] {
    const editColums = (this.states.table.columns.getCurrentValue() || []);

    return editColums.concat(internalColumnDetails);
  }

  public buildCell(workPackage:WorkPackageResource, column:string, row:HTMLElement):void {
    switch (column) {
      case internalColumnDetails:
        this.detailsLinkBuilder.build(workPackage, row);
        break;
      default:
        const cell = this.cellBuilder.build(workPackage, column);
        row.appendChild(cell);
    }

  }

  /**
   * Build the columns on the given empty row
   */
  public buildEmpty(workPackage:WorkPackageResource):HTMLElement {
    let row = this.createEmptyRow(workPackage);

    this.columns.forEach((column:string) => {
      this.buildCell(workPackage, column, row);
    });

    // Set the row selection state
    if (this.wpTableSelection.isSelected(<string>workPackage.id)) {
      row.classList.add(checkedClassName);
    }

    return row;
  }

  /**
   * Create an empty unattached row element for the given work package
   * @param workPackage
   * @returns {any}
   */
  public createEmptyRow(workPackage:WorkPackageResource) {
    let tr = document.createElement('tr');
    tr.id = rowId(workPackage.id);
    tr.dataset['workPackageId'] = workPackage.id;
    tr.classList.add(rowClassName, 'wp--row', 'issue');

    return tr;
  }

}


SingleRowBuilder.$inject = ['states', 'wpTableSelection', 'I18n'];
