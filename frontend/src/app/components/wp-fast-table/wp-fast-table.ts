import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {debugLog} from '../../helpers/debug_output';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';

import {States} from '../states.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageTimelineTableController} from '../wp-table/timeline/container/wp-timeline-container.directive';
import {GroupedRowsBuilder} from './builders/modes/grouped/grouped-rows-builder';
import {HierarchyRowsBuilder} from './builders/modes/hierarchy/hierarchy-rows-builder';
import {PlainRowsBuilder} from './builders/modes/plain/plain-rows-builder';
import {RowsBuilder} from './builders/modes/rows-builder';
import {PrimaryRenderPass} from './builders/primary-render-pass';
import {WorkPackageTableEditingContext} from './wp-table-editing';

import {WorkPackageTableRow} from './wp-table.interfaces';
import {WorkPackageTableConfiguration} from 'core-app/components/wp-table/wp-table-configuration';
import {RenderedWorkPackage} from "core-app/modules/work_packages/render-info/rendered-work-package.type";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class WorkPackageTable {

  @InjectField() querySpace:IsolatedQuerySpace;
  @InjectField() wpCacheService:WorkPackageCacheService;
  @InjectField() states:States;
  @InjectField() I18n:I18nService;

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
  public lastRenderPass:PrimaryRenderPass|null = null;

  // Work package editing context handler in the table, which handles open forms
  // and their contexts
  public editing:WorkPackageTableEditingContext = new WorkPackageTableEditingContext(this, this.injector);

  constructor(public readonly injector:Injector,
              public tableAndTimelineContainer:HTMLElement,
              public scrollContainer:HTMLElement,
              public tbody:HTMLElement,
              public timelineBody:HTMLElement,
              public timelineController:WorkPackageTimelineTableController,
              public configuration:WorkPackageTableConfiguration) {
  }

  public get renderedRows() {
    return this.querySpace.tableRendered.getValueOr([]);
  }

  public findRenderedRow(classIdentifier:string):[number, RenderedWorkPackage] {
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
      let wpId = wp.id!;

      // Ensure we get the latest version
      wp = this.wpCacheService.current(wpId, wp)!;

      this.originalRowIndex[wpId] = <WorkPackageTableRow>{ object: wp, workPackageId: wpId, position: i };
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
    const renderPass = this.performRenderPass(false);

    // Insert timeline body
    requestAnimationFrame(() => {
      this.tbody.innerHTML = '';
      this.timelineBody.innerHTML = '';
      this.tbody.appendChild(renderPass.tableBody);
      this.timelineBody.appendChild(renderPass.timeline.timelineBody);

      // Mark rendering event in a timeout to let DOM process
      setTimeout(() =>
        this.querySpace.tableRendered.putValue(renderPass.result)
      );
    });
  }

  /**
   * Redraw all elements in the table section only
   */
  public redrawTable() {
    const renderPass = this.performRenderPass();
    this.querySpace.tableRendered.putValue(renderPass.result);
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
      if (row.workPackage && row.workPackage.id === workPackage.id!) {
        debugLog(`Refreshing rendered row ${row.classIdentifier}`);
        row.workPackage = workPackage;
        pass.refresh(row, workPackage, this.tbody);
      }
    });
  }

  /**
   * Determine whether we need an empty placeholder row.
   * When D&D is enabled, the table requires a drag target that is non-empty,
   * and the tbody cannot be resized appropriately.
   */
  public get renderPlaceholderRow() {
    return this.configuration.dragAndDropEnabled;
  }


  /**
   * Perform the render pass
   * @param insert whether to insert the result (set to false for timeline)
   */
  private performRenderPass(insert:boolean = true) {
    this.editing.reset();
    const renderPass = this.lastRenderPass = this.rowBuilder.buildRows();

    // Insert table body
    if (insert) {
      requestAnimationFrame(() => {
        this.tbody.innerHTML = '';
        this.tbody.appendChild(renderPass.tableBody);
      });
    }

    return renderPass;
  }
}
