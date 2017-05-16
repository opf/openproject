import {WorkPackageTableSelection} from "../../state/wp-table-selection.service";
import {CellBuilder} from "../cell-builder";
import {DetailsLinkBuilder} from "../details-link-builder";
import {$injectFields} from "../../../angular/angular-injector-bridge.functions";
import {WorkPackageResource} from "../../../api/api-v3/hal-resources/work-package-resource.service";
import {WorkPackageTableColumnsService} from "../../state/wp-table-columns.service";
import {QueryColumn} from "../../../api/api-v3/hal-resources/query-resource.service";
import {checkedClassName} from "../ui-state-link-builder";
import {rowId} from "../../helpers/wp-table-row-helpers";
import {Observable} from "rxjs";
import {WorkPackageTable} from "../../wp-fast-table";

// Work package table row entries
export const rowClassName = 'wp-table--row';
// Class name for both table and timeline rows
export const commonRowClassName = 'wp--row';

export const internalDetailsColumn = {
  id: '__internal-detailsLink'
} as QueryColumn;

export class SingleRowBuilder {
  // Injections
  public wpTableSelection:WorkPackageTableSelection;
  public wpTableColumns:WorkPackageTableColumnsService;
  public I18n:op.I18n;

  // Cell builder instance
  protected cellBuilder = new CellBuilder();
  // Details Link builder
  protected detailsLinkBuilder = new DetailsLinkBuilder();

  constructor(protected workPackageTable:WorkPackageTable) {
    $injectFields(this, 'wpTableSelection', 'wpTableColumns', 'I18n');
  }

  /**
   * Returns the current set of columns
   */
  public get columns():QueryColumn[] {
    return this.wpTableColumns.getColumns();
  }

  /**
   * Returns the current set of columns, augmented by the internal columns
   * we add for buttons and timeline.
   */
  public get augmentedColumns():QueryColumn[] {
    return this.columns.concat(internalDetailsColumn);
  }

  public buildCell(workPackage:WorkPackageResource, column:QueryColumn):HTMLElement {
    switch (column.id) {
      case internalDetailsColumn.id:
        return this.detailsLinkBuilder.build(workPackage);
      default:
        return this.cellBuilder.build(workPackage, column.id);
    }
  }

  /**
   * Build the columns on the given empty row
   */
  public buildEmpty(workPackage:WorkPackageResource):[HTMLElement,boolean] {
    let row = this.createEmptyRow(workPackage);
    let cell = null;

    this.augmentedColumns.forEach((column:QueryColumn) => {
      cell = this.buildCell(workPackage, column);
      row.appendChild(cell);
    });

    // Set the row selection state
    if (this.wpTableSelection.isSelected(<string>workPackage.id)) {
      row.classList.add(checkedClassName);
    }

    return [row, false];
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
    tr.classList.add(rowClassName, commonRowClassName, `${commonRowClassName}-${workPackage.id}`, 'issue');

    return tr;
  }
}
