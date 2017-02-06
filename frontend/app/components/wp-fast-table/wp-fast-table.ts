import {RowsBuilder} from './builders/rows/rows-builder';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';

import {States} from '../states.service';
import {injectorBridge} from '../angular/angular-injector-bridge.functions';

import {WorkPackageTableRow} from './wp-table.interfaces';
import {TableHandlerRegistry} from './handlers/table-handler-registry';
import {locateRow} from './helpers/wp-table-row-helpers';
import {GroupedRowsBuilder} from './builders/rows/grouped-rows-builder';
import {PlainRowsBuilder} from './builders/rows/plain-rows-builder';
import {EmptyRowsBuilder} from './builders/rows/empty-rows-builder';

export class WorkPackageTable {
  public wpCacheService:WorkPackageCacheService;
  public states:States;
  public I18n:op.I18n;

  public rows: string[] = [];
  public rowIndex:{[id: string]: WorkPackageTableRow} = {};


  private groupedRowsBuilder = new GroupedRowsBuilder();
  private emptyRowsBuilder = new EmptyRowsBuilder();
  private plainRowsBuilder = new PlainRowsBuilder();

  constructor(public tbody:HTMLElement) {
    injectorBridge(this);
    TableHandlerRegistry.attachTo(this);
  }

  public rowObject(workPackageId):WorkPackageTableRow {
    return this.rowIndex[workPackageId];
  }

  /**
   * Returns the reference to the last table.metadata state value
   */
  public get metaData() {
    return this.states.table.metadata.getCurrentValue();
  }

  public get rowBuilder():RowsBuilder {
    if (this.rows.length === 0) {
      return this.emptyRowsBuilder;
    }
    else if (this.metaData.groupBy) {
      return this.groupedRowsBuilder;
    } else {
      return this.plainRowsBuilder;
    }
  }

  /**
   * Build the row index and positions from the given set of ordered work packages.
   * @param rows
   */
  private buildIndex(rows) {
    this.rowIndex = {};
    rows.forEach((wpId:string, i:number) => {
      let wp = this.states.workPackages.get(wpId).getCurrentValue();
      this.rowIndex[wpId] = <WorkPackageTableRow> { object: wp, workPackageId: wpId, position: i };
    });

    this.rows = rows;
  }
  /**
   *
   * @param rows
   */
  public initialSetup(rows:string[]) {
    // Build the row representation
    this.buildIndex(rows);

    // Draw work packages
    this.refreshBody();

    // Preselect first work package as focused
    if (this.rows.length) {
      this.states.focusedWorkPackage.put(this.rows[0]);
    }
  }

  /**
   * Removes the contents of this table's tbody and redraws
   * all elements.
   */
  public refreshBody() {
    let newBody = this.rowBuilder.buildRows(this);

    this.tbody.innerHTML = '';
    this.tbody.appendChild(newBody);
  }

  /**
   * Redraw a single row after structural changes
   */
  public refreshRow(row:WorkPackageTableRow) {
    // Find the row we want to replace
    let oldRow = row.element || locateRow(row.workPackageId);
    let newRow = this.rowBuilder.refreshRow(row, this);
    oldRow.parentNode.replaceChild(newRow, oldRow);

    row.element = newRow;
    this.rowIndex[row.workPackageId] = row;
  }

  /**
   * Update the rendered state that the table is now refreshed.
   */
  public postRender() {
    this.states.table.rendered.put(this);
  }
}

WorkPackageTable.$inject = ['wpCacheService', 'states', 'I18n'];
