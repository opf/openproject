import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {debugLog} from '../../helpers/debug_output';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';

import {States} from '../states.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageTimelineTableController} from '../wp-table/timeline/container/wp-timeline-container.directive';
import {GroupedRowsBuilder} from './builders/modes/grouped/grouped-rows-builder';
import {HierarchyRowsBuilder} from './builders/modes/hierarchy/hierarchy-rows-builder';
import {PlainRowsBuilder} from './builders/modes/plain/plain-rows-builder';
import {RowsBuilder} from './builders/modes/rows-builder';
import {PrimaryRenderPass, RenderedRow} from './builders/primary-render-pass';
import {WorkPackageTableEditingContext} from './wp-table-editing';

import {WorkPackageTableRow} from './wp-table.interfaces';
import {WorkPackageTableConfiguration, WorkPackageTableConfigurationObject} from 'core-app/components/wp-table/wp-table-configuration';

export class WorkPackageTable {

  private readonly tableState:TableState = this.injector.get(TableState);

  public wpCacheService:WorkPackageCacheService = this.injector.get(WorkPackageCacheService);
  public states:States = this.injector.get(States);
  public I18n:I18nService = this.injector.get(I18nService);

  public originalRows:string[] = [];
  public originalRowIndex:{ [id:string]:WorkPackageTableRow } = {};

  // WP rows builder
  // Ordered by priority
  private builders = [
    new HierarchyRowsBuilder(this.injector, this),
    new GroupedRowsBuilder(this.injector, this),
    new PlainRowsBuilder(this.injector, this)
  ];

  // Last render pass used for refreshing single rows
  private lastRenderPass:PrimaryRenderPass | null = null;

  // Work package editing context handler in the table, which handles open forms
  // and their contexts
  public editing:WorkPackageTableEditingContext = new WorkPackageTableEditingContext(this, this.injector);

  constructor(public readonly injector:Injector,
              public container:HTMLElement,
              public tbody:HTMLElement,
              public timelineBody:HTMLElement,
              public timelineController:WorkPackageTimelineTableController,
              public configuration:WorkPackageTableConfiguration) {
  }

  public get renderedRows() {
    return this.tableState.rendered.getValueOr([]);
  }

  public findRenderedRow(classIdentifier:string):[number, RenderedRow] {
    const index = _.findIndex(this.renderedRows, (row) => row.classIdentifier === classIdentifier);

    return [index, this.renderedRows[index]];
  }

  public get rowBuilder():RowsBuilder {
    return _.find(this.builders, (builder:RowsBuilder) => builder.isApplicable(this))!;
  }

  /**
   * Build the row index and positions from the given set of ordered work packages.
   * @param rows
   */
  private buildIndex(rows:WorkPackageResource[]) {
    this.originalRowIndex = {};
    this.originalRows = rows.map((wp:WorkPackageResource, i:number) => {
      let wpId = wp.id;
      this.originalRowIndex[wpId] = <WorkPackageTableRow> {object: wp, workPackageId: wpId, position: i};
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
    const renderPass = this.performRenderPass();

    // Insert timeline body
    this.timelineBody.innerHTML = '';
    this.timelineBody.appendChild(renderPass.timeline.timelineBody);

    this.tableState.rendered.putValue(renderPass.result);
  }

  /**
   * Redraw all elements in the table section only
   */
  public redrawTable() {
    const renderPass = this.performRenderPass();
    this.tableState.rendered.putValue(renderPass.result);
  }

  /**
   * Redraw single rows for a given work package being updated.
   */
  public refreshRows(workPackage:WorkPackageResource) {
    const pass = this.lastRenderPass;
    if (!pass) {
      debugLog('Trying to refresh a singular row without a previous render pass.');
      return;
    }

    _.each(pass.renderedOrder, (row) => {
      if (row.workPackage && row.workPackage.id === workPackage.id) {
        debugLog(`Refreshing rendered row ${row.classIdentifier}`);
        row.workPackage = workPackage;
        pass.refresh(row, workPackage, this.tbody);
      }
    });
  }

  private performRenderPass() {
    this.editing.reset();
    const renderPass = this.lastRenderPass = this.rowBuilder.buildRows();

    // Insert table body
    this.tbody.innerHTML = '';
    this.tbody.appendChild(renderPass.tableBody);

    return renderPass;
  }
}
