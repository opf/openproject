import {WorkPackageResource} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {CellBuilder} from './cell-builder';
import {States} from '../../states.service';
import {injectorBridge} from '../../angular/angular-injector-bridge.functions';
import {DetailsLinkBuilder} from './details-link-builder';
import {WorkPackageTableSelection} from '../state/wp-table-selection.service';
export const rowClassName = 'wp-table--row';

export class RowBuilder {
  // Injections
  public states:States;
  public wpTableSelection:WorkPackageTableSelection;
  public I18n:op.I18n;

  // Cell builder instance
  private cellBuilder = new CellBuilder();
  // Details Link builder
  private detailsLinkBuilder = new DetailsLinkBuilder();

  constructor() {
    injectorBridge(this);
  }

  public createEmptyRow(workPackage) {
    let tr = document.createElement('tr');
    tr.id = 'wp-row-' + workPackage.id;
    tr.dataset['workPackageId'] = workPackage.id;

    return tr;
  }

  /**
   * Returns a shortcut to the current column state.
   * It is not responsible for subscribing to updates.
   */
  public get columns():string[] {
    return this.states.table.columns.getCurrentValue();
  }

  public build(workPackage:WorkPackageResource, row:HTMLElement) {
    row.id = `wp-row-${workPackage.id}`;
    row.classList.add('wp-table--row', 'wp--row', 'issue');

    this.columns.forEach((column:string) => {
      let cell = this.cellBuilder.build(workPackage, column);
      row.appendChild(cell);
    });

    // Last column: details link
    this.detailsLinkBuilder.build(workPackage, row);

    // Set the row selection state
    if (this.wpTableSelection.isSelected(<string>workPackage.id)) {
      row.classList.add('-checked');
    }
  }
}


RowBuilder.$inject = ['states', 'wpTableSelection', 'I18n'];
