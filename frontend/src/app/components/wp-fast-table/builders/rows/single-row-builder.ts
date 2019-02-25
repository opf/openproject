import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {locateTableRowByIdentifier} from 'core-components/wp-fast-table/helpers/wp-table-row-helpers';
import {debugLog} from '../../../../helpers/debug_output';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {isRelationColumn, QueryColumn} from '../../../wp-query/query-column';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {CellBuilder, wpCellTdClassName} from '../cell-builder';
import {RelationCellbuilder} from '../relation-cell-builder';
import {checkedClassName} from '../ui-state-link-builder';
import {TableActionRenderer} from 'core-components/wp-fast-table/builders/table-action-renderer';

// Work package table row entries
export const tableRowClassName = 'wp-table--row';
// Work package and timeline rows
export const commonRowClassName = 'wp--row';

export const internalContextMenuColumn = {
  id: '__internal-contextMenu'
} as QueryColumn;

export class SingleRowBuilder {

  // Injections
  public wpTableSelection = this.injector.get(WorkPackageTableSelection);
  public wpTableColumns = this.injector.get(WorkPackageTableColumnsService);
  public I18n:I18nService = this.injector.get(I18nService);

  // Cell builder instance
  protected cellBuilder = new CellBuilder(this.injector);
  // Relation cell builder instance
  protected relationCellBuilder = new RelationCellbuilder(this.injector);

  // Details Link builder
  protected contextLinkBuilder = new TableActionRenderer(this.injector);

  constructor(public readonly injector:Injector,
              protected workPackageTable:WorkPackageTable) {
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
    return this.columns.concat([internalContextMenuColumn]);
  }

  public buildCell(workPackage:WorkPackageResource, column:QueryColumn):HTMLElement|null {
    // handle relation types
    if (isRelationColumn(column)) {
      return this.relationCellBuilder.build(workPackage, column);
    }

    // Handle property types
    switch (column.id) {
      case internalContextMenuColumn.id:
        if (this.workPackageTable.configuration.actionsColumnEnabled) {
          return this.contextLinkBuilder.build(workPackage);
        } else if (this.workPackageTable.configuration.columnMenuEnabled) {
          let td = document.createElement('td');
          td.classList.add('hide-when-print');
          return td;
        } else {
          return null;
        }
      default:
        return this.cellBuilder.build(workPackage, column.id);
    }
  }

  /**
   * Build the columns on the given empty row
   */
  public buildEmpty(workPackage:WorkPackageResource):[HTMLElement, boolean] {
    let row = this.createEmptyRow(workPackage);
    return this.buildEmptyRow(workPackage, row);
  }

  /**
   * Create an empty unattached row element for the given work package
   * @param workPackage
   * @returns {any}
   */
  public createEmptyRow(workPackage:WorkPackageResource) {
    const identifier = this.classIdentifier(workPackage);
    let tr = document.createElement('tr');
    tr.setAttribute('tabindex', '0');
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

  public classIdentifier(workPackage:WorkPackageResource) {
    return `wp-row-${workPackage.id}`;
  }

  /**
   * Refresh a row that is currently being edited, that is, some edit fields may be open
   */
  public refreshRow(workPackage:WorkPackageResource, jRow:JQuery):JQuery {
    // Detach all current edit cells
    const cells = jRow.find(`.${wpCellTdClassName}`).detach();

    // Remember the order of all new edit cells
    const newCells:HTMLElement[] = [];

    this.augmentedColumns.forEach((column:QueryColumn) => {
      const oldTd = cells.filter(`td.${column.id}`);

      // Skip the replacement of the column if this is being edited.
      if (this.isColumnBeingEdited(workPackage, column)) {
        newCells.push(oldTd[0]);
        return;
      }

      // Otherwise, refresh that cell and append it
      const cell = this.buildCell(workPackage, column);

      if (cell) {
        newCells.push(cell);
      }
    });

    jRow.prepend(newCells);
    return jRow;
  }

  protected isColumnBeingEdited(workPackage:WorkPackageResource, column:QueryColumn) {
    const form = this.workPackageTable.editing.forms[workPackage.id];

    return form && form.activeFields[column.id];
  }

  protected buildEmptyRow(workPackage:WorkPackageResource, row:HTMLElement):[HTMLElement, boolean] {
    const changeset = this.workPackageTable.editing.changeset(workPackage.id);
    let cells:{ [attribute:string]:JQuery } = {};

    if (changeset && !changeset.empty) {
      // Try to find an old instance of this row
      const oldRow = locateTableRowByIdentifier(this.classIdentifier(workPackage));

      changeset.changedAttributes.forEach((attribute:string) => {
        cells[attribute] = oldRow.find(`.${wpCellTdClassName}.${attribute}`);
      });
    }

    this.augmentedColumns.forEach((column:QueryColumn) => {
      let cell:Element|null;
      let oldCell:JQuery|undefined = cells[column.id];

      if (oldCell && oldCell.length) {
        debugLog(`Rendering previous open column ${column.id} on ${workPackage.id}`);
        jQuery(row).append(oldCell);
      } else {
        cell = this.buildCell(workPackage, column);

        if (cell) {
          row.appendChild(cell);
        }
      }
    });

    // Set the row selection state
    if (this.wpTableSelection.isSelected(workPackage.id)) {
      row.classList.add(checkedClassName);
    }

    return [row, false];
  }
}
