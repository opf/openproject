import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';

import {States} from '../states.service';
import {injectorBridge} from '../angular/angular-injector-bridge.functions';

import {WorkPackageTableRow} from './wp-table.interfaces';
import {TableHandlerRegistry} from './handlers/table-handler-registry';
import {locateRow} from './helpers/wp-table-row-helpers';
import {PlainRowsBuilder} from "./builders/modes/plain/plain-rows-builder";
import {GroupedRowsBuilder} from "./builders/modes/grouped/grouped-rows-builder";
import {HierarchyRowsBuilder} from "./builders/modes/hierarchy/hierarchy-rows-builder";
import {RowsBuilder} from "./builders/modes/rows-builder";
import {WorkPackageTimelineTableController} from "../wp-table/timeline/container/wp-timeline-container.directive";
import {TableRenderPass} from './builders/modes/table-render-pass';
import {Subject} from 'rxjs';

export class WorkPackageTable {
  public wpCacheService:WorkPackageCacheService;
  public states:States;
  public I18n:op.I18n;

  public rows:string[] = [];
  public rowIndex:{[id:string]:WorkPackageTableRow} = {};

  // WP rows builder
  // Ordered by priority
  private builders = [
    new HierarchyRowsBuilder(this),
    new GroupedRowsBuilder(this),
    new PlainRowsBuilder(this)
  ];

  constructor(public container:HTMLElement,
              public tbody:HTMLElement,
              public timelineBody:HTMLElement,
              public timelineController:WorkPackageTimelineTableController) {
    injectorBridge(this);
    TableHandlerRegistry.attachTo(this);
  }

  public rowObject(workPackageId:string):WorkPackageTableRow {
    return this.rowIndex[workPackageId];
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
    this.redrawTableAndTimeline();
  }

  /**
   * Removes the contents of this table's tbody and redraws
   * all elements.
   */
  public redrawTableAndTimeline() {
    const renderPass = this.rowBuilder.buildRows();

    // Insert table body
    this.tbody.innerHTML = '';
    this.tbody.appendChild(renderPass.tableBody);

    // Insert timeline body
    this.timelineBody.innerHTML = '';
    this.timelineBody.appendChild(renderPass.timelineBody);

    this.states.table.rendered.putValue(renderPass.result);
  }

  /**
   * Redraw all elements in the table section only
   */
  public redrawTable() {
    const renderPass = this.rowBuilder.buildRows();

    this.tbody.innerHTML = '';
    this.tbody.appendChild(renderPass.tableBody);

    this.states.table.rendered.putValue(renderPass.result);
  }

  /**
   * Redraw a single row after structural changes
   */
  public refreshRow(row:WorkPackageTableRow) {
    // Find the row we want to replace
    let oldRow = row.element || locateRow(row.workPackageId);
    let result = this.rowBuilder.refreshRow(row);

    if (result !== null && oldRow && oldRow.parentNode) {
      let [newRow, _hidden] = result;
      oldRow.parentNode.replaceChild(newRow, oldRow);
      row.element = newRow;
      this.rowIndex[row.workPackageId] = row;
    }
  }
}

WorkPackageTable.$inject = ['wpCacheService', 'states', 'I18n'];
