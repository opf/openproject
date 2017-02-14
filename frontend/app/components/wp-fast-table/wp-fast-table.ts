import {HierarchyRowsBuilder} from './builders/rows/hierarchy-rows-builder';
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
import {WorkPackageTimelineTableController} from "../wp-table/timeline/wp-timeline-container.directive";

export class WorkPackageTable {
  public wpCacheService:WorkPackageCacheService;
  public states:States;
  public I18n:op.I18n;

  public rows: string[] = [];
  public rowIndex:{[id: string]: WorkPackageTableRow} = {};

  // WP rows builder
  // Ordered by priority
  private builders = [
    new HierarchyRowsBuilder(this),
    new GroupedRowsBuilder(this),
    new PlainRowsBuilder(this)
  ];

  constructor(public container:HTMLElement,
              public tbody:HTMLElement,
              public timelineController: WorkPackageTimelineTableController) {
    injectorBridge(this);
    TableHandlerRegistry.attachTo(this);
  }

  public rowObject(workPackageId:string):WorkPackageTableRow {
    return this.rowIndex[workPackageId];
  }

  /**
   * Returns the reference to the last table.query state value
   */
  public get query() {
    return this.states.table.query.getCurrentValue();
  }

  public get rowBuilder():RowsBuilder {
    return _.find(this.builders, (builder:RowsBuilder) => builder.isApplicable(this))!;
  }

  /**
   * Build the row index and positions from the given set of ordered work packages.
   * @param rows
   */
  private buildIndex(rows:WorkPackageResource[]) {
    this.rowIndex = {};
    this.rows = rows.map((wp:WorkPackageResource, i:number) => {
      let wpId = wp.id;
      this.rowIndex[wpId] = <WorkPackageTableRow> { object: wp, workPackageId: wpId, position: i };
      return wpId;
    });
  }
  /**
   *
   * @param rows
   */
  public initialSetup(rows:WorkPackageResource[]) {
    // Build the row representation
    this.buildIndex(rows);

    // Draw work packages
    this.refreshBody();

    // Preselect first work package as focused
    if (this.rows.length && this.states.focusedWorkPackage.isPristine()) {
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

    if (newRow && oldRow && oldRow.parentNode) {
      oldRow.parentNode.replaceChild(newRow, oldRow);
      row.element = newRow;
      this.rowIndex[row.workPackageId] = row;
    }
  }

  /**
   * Update the rendered state that the table is now refreshed.
   */
  public postRender() {
    this.states.table.rendered.put(this);
  }
}

WorkPackageTable.$inject = ['wpCacheService', 'states', 'I18n'];
