import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {CellBuilder, wpCellTdClassName} from '../cell-builder';
import {DetailsLinkBuilder} from '../details-link-builder';
import {$injectFields} from '../../../angular/angular-injector-bridge.functions';
import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {checkedClassName} from '../ui-state-link-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {isRelationColumn, QueryColumn} from '../../../wp-query/query-column';
import {RelationCellbuilder} from '../relation-cell-builder';
import {WorkPackageEditForm} from '../../../wp-edit-form/work-package-edit-form';
import {WorkPackageChangeset} from '../../../wp-edit-form/work-package-changeset';

// Work package table row entries
export const tableRowClassName = 'wp-table--row';
// Work package and timeline rows
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
  // Relation cell builder instance
  protected relationCellBuilder = new RelationCellbuilder();

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

  public buildCell(workPackage:WorkPackageResourceInterface, column:QueryColumn):HTMLElement {

    // handle relation types
    if (isRelationColumn(column)) {
      return this.relationCellBuilder.build(workPackage, column);
    }

    // Handle property types
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
  public buildEmpty(workPackage:WorkPackageResourceInterface):[HTMLElement, boolean] {
    let row = this.createEmptyRow(workPackage);
    return this.buildEmptyRow(workPackage, row);
  }

  /**
   * Create an empty unattached row element for the given work package
   * @param workPackage
   * @returns {any}
   */
  public createEmptyRow(workPackage:WorkPackageResourceInterface) {
    const identifier = this.classIdentifier(workPackage);
    let tr = document.createElement('tr');
    tr.dataset['workPackageId'] = workPackage.id;
    tr.dataset['classIdentifier'] = identifier;
    tr.classList.add(
      tableRowClassName,
      commonRowClassName,
      identifier,
      `${identifier}-table`,
      'issue'
    );

    return tr;
  }

  public classIdentifier(workPackage:WorkPackageResourceInterface) {
    return `wp-row-${workPackage.id}`;
  }

  /**
   * Refresh a row that is currently being edited, that is, some edit fields may be open
   */
  public refreshRow(workPackage:WorkPackageResourceInterface, changeset:WorkPackageChangeset, jRow:JQuery):JQuery {
    // Detach all current edit cells
    const cells = jRow.find(`.${wpCellTdClassName}`).detach();

    // Remember the order of all new edit cells
    const newCells:HTMLElement[] = [];

    this.columns.forEach((column:QueryColumn) => {
      const oldTd = cells.filter(`td.${column.id}`);

      // Skip the replacement of the column if this is being edited.
      if (this.isColumnBeingEdited(changeset, column)) {
        newCells.push(oldTd[0]);
        return;
      }

      // Otherwise, refresh that cell and append it
      const cell = this.buildCell(workPackage, column);
      newCells.push(cell);
    });

    jRow.prepend(newCells);
    return jRow;
  }

  protected isColumnBeingEdited(changeset:WorkPackageChangeset, column:QueryColumn) {
    return changeset && changeset.isOverridden(column.id);
  }

  protected buildEmptyRow(workPackage:WorkPackageResourceInterface, row:HTMLElement):[HTMLElement, boolean] {
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
}
