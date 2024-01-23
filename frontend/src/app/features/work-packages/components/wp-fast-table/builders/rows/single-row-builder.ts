import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { locateTableRowByIdentifier } from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-row-helpers';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { TableActionRenderer } from 'core-app/features/work-packages/components/wp-fast-table/builders/table-action-renderer';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import {
  internalBaselineColumn,
  internalContextMenuColumn,
  internalSortColumn,
  sharedUserColumn,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/internal-sort-columns';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { checkedClassName } from '../ui-state-link-builder';
import { RelationCellbuilder } from '../relation-cell-builder';
import {
  CellBuilder,
  tdClassName,
} from '../cell-builder';
import {
  isRelationColumn,
  QueryColumn,
} from '../../../wp-query/query-column';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { BaselineColumnBuilder } from 'core-app/features/work-packages/components/wp-fast-table/builders/baseline/baseline-column-builder';
import { ShareCellbuilder } from '../share-cell-builder';

// Work package table row entries
export const tableRowClassName = 'wp-table--row';
// Work package and timeline rows
export const commonRowClassName = 'wp--row';

export class SingleRowBuilder {
  // Injections
  @InjectField() wpTableSelection:WorkPackageViewSelectionService;

  @InjectField() wpTableColumns:WorkPackageViewColumnsService;

  @InjectField() wpTableBaseline:WorkPackageViewBaselineService;

  @InjectField() I18n!:I18nService;

  // Cell builder instance
  protected cellBuilder = new CellBuilder(this.injector);

  // Relation cell builder instance
  protected relationCellBuilder = new RelationCellbuilder(this.injector);

  // Share cell builder instance
  protected shareCellBuilder = new ShareCellbuilder(this.injector);

  // Details Link builder
  protected contextLinkBuilder = new TableActionRenderer(this.injector);

  // Baseline column builder
  protected baselineColumnBuilder = new BaselineColumnBuilder(this.injector);

  // Build the augmented columns set to render with
  protected readonly augmentedColumns:QueryColumn[] = this.buildAugmentedColumns();

  constructor(
    public readonly injector:Injector,
    protected workPackageTable:WorkPackageTable,
  ) {
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
  private buildAugmentedColumns():QueryColumn[] {
    const columns = [...this.columns, internalContextMenuColumn];

    if (this.wpTableBaseline.isActive()) {
      columns.unshift(internalBaselineColumn);
    }

    if (this.workPackageTable.configuration.dragAndDropEnabled) {
      columns.unshift(internalSortColumn);
    }

    return columns;
  }

  public buildCell(workPackage:WorkPackageResource, column:QueryColumn):HTMLElement|null {
    // handle relation types
    if (isRelationColumn(column)) {
      return this.relationCellBuilder.build(workPackage, column);
    }

    if (column.id === sharedUserColumn.id) {
      return this.shareCellBuilder.build(workPackage, column);
    }

    // Handle property types
    switch (column.id) {
      case internalContextMenuColumn.id:
        if (this.workPackageTable.configuration.actionsColumnEnabled) {
          return this.contextLinkBuilder.build(workPackage);
        }
        if (this.workPackageTable.configuration.columnMenuEnabled) {
          const td = document.createElement('td');
          td.classList.add('hide-when-print');
          return td;
        }
        return null;

      case internalBaselineColumn.id:
        return this.baselineColumnBuilder.build(workPackage, column);

      default:
        return this.cellBuilder.build(workPackage, column);
    }
  }

  /**
   * Build the columns on the given empty row
   */
  public buildEmpty(workPackage:WorkPackageResource):[HTMLTableRowElement, boolean] {
    const row = this.createEmptyRow(workPackage);
    return this.buildEmptyRow(workPackage, row);
  }

  /**
   * Create an empty unattached row element for the given work package
   * @param workPackage
   * @returns {any}
   */
  public createEmptyRow(workPackage:WorkPackageResource) {
    const identifier = this.classIdentifier(workPackage);
    const tr = document.createElement('tr');
    tr.setAttribute('tabindex', '0');
    tr.dataset.workPackageId = workPackage.id!;
    tr.dataset.classIdentifier = identifier;
    tr.classList.add(
      tableRowClassName,
      commonRowClassName,
      identifier,
      `${identifier}-table`,
      'issue',
    );

    return tr;
  }

  /**
   * In case the table will end up empty, we insert a placeholder
   * row to provide some space within the tbody.
   */
  public get placeholderRow() {
    const tr:HTMLTableRowElement = document.createElement('tr');
    const td:HTMLTableCellElement = document.createElement('td');

    tr.classList.add('wp--placeholder-row');
    td.colSpan = this.augmentedColumns.length;
    tr.appendChild(td);

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
    const cells = jRow.find(`.${tdClassName}`).detach();

    // Remember the order of all new edit cells
    const newCells:HTMLElement[] = [];

    this.augmentedColumns.forEach((column:QueryColumn) => {
      const oldTd = cells.filter(`td.${column.id}`);

      // Treat internal columns specially
      // and skip the replacement of the column if this is being edited.
      // But only do that, if the column existed before. Sometimes, e.g. when lacking permissions
      // the column was not correctly created (with the intended classes). This code then
      // increases the robustness.
      if ((column.id.startsWith('__internal') || this.isColumnBeingEdited(workPackage, column)) && oldTd.length) {
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
    const form = this.workPackageTable.editing.forms[workPackage.id!];

    return form && form.activeFields[column.id];
  }

  protected buildEmptyRow(workPackage:WorkPackageResource, row:HTMLTableRowElement):[HTMLTableRowElement, boolean] {
    const change = this.workPackageTable.editing.change(workPackage);
    const cells:{ [attribute:string]:JQuery } = {};

    if (change && !change.isEmpty()) {
      // Try to find an old instance of this row
      const oldRow = locateTableRowByIdentifier(this.classIdentifier(workPackage));

      change.changedAttributes.forEach((attribute:string) => {
        cells[attribute] = oldRow.find(`.${tdClassName}.${attribute}`);
      });
    }

    this.augmentedColumns.forEach((column:QueryColumn) => {
      let cell:Element|null;
      const oldCell:JQuery|undefined = cells[column.id];

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
    if (this.wpTableSelection.isSelected(workPackage.id!)) {
      row.classList.add(checkedClassName);
    }

    return [row, false];
  }
}
