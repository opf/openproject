//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

import { AfterViewInit, Component, ElementRef, Injector } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { INotification, NotificationsService } from 'core-app/modules/common/notifications/notifications.service';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { IsolatedQuerySpace } from 'core-app/modules/work_packages/query-space/isolated-query-space';
import * as moment from 'moment';
import { Moment } from 'moment';
import { filter, takeUntil } from 'rxjs/operators';
import {
  calculateDaySpan,
  getPixelPerDayForZoomLevel,
  requiredPixelMarginLeft,
  timelineElementCssClass,
  timelineHeaderSelector,
  timelineMarkerSelectionStartClass,
  TimelineViewParameters,
  zoomLevelOrder
} from '../wp-timeline';
import { input, InputState } from 'reactivestates';
import { WorkPackageTable } from 'core-components/wp-fast-table/wp-fast-table';
import { WorkPackageTimelineCellsRenderer } from 'core-components/wp-table/timeline/cells/wp-timeline-cells-renderer';
import { States } from 'core-components/states.service';
import { WorkPackageViewTimelineService } from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { WorkPackageRelationsService } from 'core-components/wp-relations/wp-relations.service';
import { WorkPackageViewHierarchiesService } from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageTimelineCell } from 'core-components/wp-table/timeline/cells/wp-timeline-cell';
import { selectorTimelineSide } from 'core-components/wp-table/wp-table-scroll-sync';
import { debugLog, timeOutput } from 'core-app/helpers/debug_output';
import { RenderedWorkPackage } from 'core-app/modules/work_packages/render-info/rendered-work-package.type';
import { HalEventsService } from 'core-app/modules/hal/services/hal-events.service';
import { WorkPackageNotificationService } from 'core-app/modules/work_packages/notifications/work-package-notification.service';
import { combineLatest, Observable } from 'rxjs';
import { UntilDestroyedMixin } from 'core-app/helpers/angular/until-destroyed.mixin';
import { WorkPackagesTableComponent } from 'core-components/wp-table/wp-table.component';
import {
  groupIdFromIdentifier,
  groupTypeFromIdentifier
} from 'core-components/wp-fast-table/builders/modes/grouped/grouped-rows-helpers';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';

@Component({
  selector: 'wp-timeline-container',
  templateUrl: './wp-timeline-container.html'
})
export class WorkPackageTimelineTableController extends UntilDestroyedMixin implements AfterViewInit {
  private $element:JQuery;

  public workPackageTable:WorkPackageTable;

  private _viewParameters:TimelineViewParameters = new TimelineViewParameters();

  public disableViewParamsCalculation = false;

  public workPackageIdOrder:RenderedWorkPackage[] = [];

  private renderers:{ [name:string]:(vp:TimelineViewParameters) => void } = {};

  private cellsRenderer = new WorkPackageTimelineCellsRenderer(this.injector, this);

  public outerContainer:JQuery;

  public timelineBody:JQuery;

  private selectionParams:{ notification:INotification|null } = {
    notification: null
  };

  private text:{ selectionMode:string };

  private refreshRequest = input<void>();

  private collapsedGroupsCellsMap:IGroupCellsMap = {};

  private orderedRows:RenderedWorkPackage[] = [];

  get commonPipes() {
    return (source:Observable<any>) => {
      return source.pipe(
        this.untilDestroyed(),
        takeUntil(this.querySpace.stopAllSubscriptions),
        filter(() => this.initialized && this.wpTableTimeline.isVisible),
      );
    };
  }

  get workPackagesWithGroupHeaderCell():RenderedWorkPackage[] {
    const tableWorkPackages = this.querySpace.results.value!.elements;
    const wpsWithGroupHeaderCell = tableWorkPackages
      .filter(tableWorkPackage => this.shouldBeShownInCollapsedGroupHeaders(tableWorkPackage))
      .map(tableWorkPackage => tableWorkPackage.id);
    const workPackagesWithGroupHeaderCell = this.orderedRows.filter(row => wpsWithGroupHeaderCell.includes(row.workPackageId!) && !this.workPackageIdOrder.includes(row));

    return workPackagesWithGroupHeaderCell;
  }

  constructor(public readonly injector:Injector,
              private elementRef:ElementRef,
              private states:States,
              public wpTableComponent:WorkPackagesTableComponent,
              private NotificationsService:NotificationsService,
              private wpTableTimeline:WorkPackageViewTimelineService,
              private notificationService:WorkPackageNotificationService,
              private wpRelations:WorkPackageRelationsService,
              private wpTableHierarchies:WorkPackageViewHierarchiesService,
              private halEvents:HalEventsService,
              private querySpace:IsolatedQuerySpace,
              readonly I18n:I18nService,
              private workPackageViewCollapsedGroupsService:WorkPackageViewCollapsedGroupsService) {
    super();
  }

  ngAfterViewInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    this.text = {
      selectionMode: this.I18n.t('js.timelines.selection_mode.notification')
    };

    // Get the outer container for width computation
    this.outerContainer = this.$element.find('.wp-table-timeline--outer');
    this.timelineBody = this.$element.find('.wp-table-timeline--body');

    // Register this instance to the table
    this.wpTableComponent.registerTimeline(this, this.timelineBody[0]);

    // Refresh on window resize events
    window.addEventListener('wp-resize.timeline', () => this.refreshRequest.putValue(undefined));

    combineLatest([
      this.querySpace.tableRendered.values$(),
      this.refreshRequest.changes$(),
      this.wpTableTimeline.live$()
    ]).pipe(
      this.commonPipes,
    )
      .subscribe(([orderedRows, changes, timelineState]) => {
      // Remember all visible rows in their order of appearance.
        this.workPackageIdOrder = orderedRows.filter((row:RenderedWorkPackage) => !row.hidden);
        this.orderedRows = orderedRows;
        this.refreshView();
      });

    this.setupManageCollapsedGroupHeaderCells();
  }

  workPackageCells(wpId:string):WorkPackageTimelineCell[] {
    return this.cellsRenderer.getCellsFor(wpId);
  }

  /**
   * Return the index of a given row by its class identifier
   */
  workPackageIndex(classIdentifier:string):number {
    return this.workPackageIdOrder.findIndex((el) => el.classIdentifier === classIdentifier);
  }

  onRefreshRequested(name:string, callback:(vp:TimelineViewParameters) => void) {
    this.renderers[name] = callback;
  }

  getAbsoluteLeftCoordinates():number {
    return this.$element.offset()!.left;
  }

  getParentScrollContainer() {
    return this.outerContainer.closest(selectorTimelineSide)[0];
  }

  get viewParameters():TimelineViewParameters {
    return this._viewParameters;
  }

  get inHierarchyMode():boolean {
    return this.wpTableHierarchies.isEnabled;
  }

  get initialized():boolean {
    return this.workPackageTable && this.querySpace.tableRendered.hasValue();
  }

  refreshView() {
    if (!this.wpTableTimeline.isVisible) {
      debugLog('refreshView() requested, but TL is invisible.');
      return;
    }

    if (this.wpTableTimeline.isAutoZoom()) {
      // Update autozoom level
      this.applyAutoZoomLevel();
    } else {
      this._viewParameters.settings.zoomLevel = this.wpTableTimeline.zoomLevel;
      this.wpTableTimeline.appliedZoomLevel = this.wpTableTimeline.zoomLevel;
    }

    timeOutput('refreshView() in timeline container', () => {
      // Reset the width of the outer container if its content shrinks
      this.outerContainer.css('width', 'auto');

      this.calculateViewParams(this._viewParameters);

      // Update all cells
      this.cellsRenderer.refreshAllCells();

      _.each(this.renderers, (cb, key) => {
        debugLog(`Refreshing timeline member ${key}`);
        cb(this._viewParameters);
      });

      this.refreshCollapsedGroupsHeaderCells(this.collapsedGroupsCellsMap, this.cellsRenderer);

      // Calculate overflowing width to set to outer container
      // required to match width in all child divs.
      // The header is the only one reliable, as it already has the final width.
      const currentWidth = this.$element.find(timelineHeaderSelector)[0].scrollWidth;
      this.outerContainer.width(currentWidth);

      // Mark rendering event in a timeout to give DOM some time
      setTimeout(() => {
        this.querySpace.timelineRendered.next(null);
      });
    });
  }

  startAddRelationPredecessor(start:WorkPackageResource) {
    this.activateSelectionMode(start.id!, end => {
      this.wpRelations
        .addCommonRelation(start.id!, 'follows', end.id!)
        .then(() => {
          this.halEvents.push(start, {
            eventType: 'association',
            relatedWorkPackage: end.id!,
            relationType: 'follows'
          });
        })
        .catch((error:any) => this.notificationService.handleRawError(error, end));
    });
  }

  startAddRelationFollower(start:WorkPackageResource) {
    this.activateSelectionMode(start.id!, end => {
      this.wpRelations
        .addCommonRelation(start.id!, 'precedes', end.id!)
        .then(() => {
          this.halEvents.push(start, {
            eventType: 'association',
            relatedWorkPackage: end.id!,
            relationType: 'precedes'
          });
        })
        .catch((error:any) => this.notificationService.handleRawError(error, end));
    });
  }

  getFirstDayInViewport() {
    const outerContainer = this.getParentScrollContainer();
    const scrollLeft = outerContainer.scrollLeft;
    const nonVisibleDaysLeft = Math.floor(scrollLeft / this.viewParameters.pixelPerDay);
    return this.viewParameters.dateDisplayStart.clone().add(nonVisibleDaysLeft, 'days');
  }

  getLastDayInViewport() {
    const outerContainer = this.getParentScrollContainer();
    const scrollLeft = outerContainer.scrollLeft;
    const width = outerContainer.offsetWidth;
    const viewPortRight = scrollLeft + width;
    const daysUntilViewPortEnds = Math.ceil(viewPortRight / this.viewParameters.pixelPerDay) + 1;
    return this.viewParameters.dateDisplayStart.clone().add(daysUntilViewPortEnds, 'days');
  }

  forceCursor(cursor:string) {
    jQuery('.' + timelineElementCssClass).css('cursor', cursor);
    jQuery('.wp-timeline-cell').css('cursor', cursor);
    jQuery('.hascontextmenu').css('cursor', cursor);
    jQuery('.leftHandle').css('cursor', cursor);
    jQuery('.rightHandle').css('cursor', cursor);
  }

  resetCursor() {
    jQuery('.' + timelineElementCssClass).css('cursor', '');
    jQuery('.wp-timeline-cell').css('cursor', '');
    jQuery('.hascontextmenu').css('cursor', '');
    jQuery('.leftHandle').css('cursor', '');
    jQuery('.rightHandle').css('cursor', '');
  }

  private resetSelectionMode() {
    this._viewParameters.activeSelectionMode = null;
    this._viewParameters.selectionModeStart = null;

    if (this.selectionParams.notification) {
      this.NotificationsService.remove(this.selectionParams.notification);
    }

    Mousetrap.unbind('esc');

    this.$element.removeClass('active-selection-mode');
    jQuery('.' + timelineMarkerSelectionStartClass).removeClass(timelineMarkerSelectionStartClass);
    this.refreshView();
  }

  private activateSelectionMode(start:string, callback:(wp:WorkPackageResource) => any) {
    start = start.toString(); // old system bug: ID can be a 'number'

    this._viewParameters.activeSelectionMode = (wp:WorkPackageResource) => {
      callback(wp);
      this.resetSelectionMode();
    };

    this._viewParameters.selectionModeStart = start;
    Mousetrap.bind('esc', () => this.resetSelectionMode());
    this.selectionParams.notification = this.NotificationsService.addNotice(this.text.selectionMode);

    this.$element.addClass('active-selection-mode');

    this.refreshView();
  }

  private calculateViewParams(currentParams:TimelineViewParameters):boolean {
    if (this.disableViewParamsCalculation) {
      return false;
    }

    const newParams = new TimelineViewParameters();
    let changed = false;
    const workPackagesToCalculateTimelineWidthFrom = this.getWorkPackagesToCalculateTimelineWidthFrom();

    workPackagesToCalculateTimelineWidthFrom.forEach((renderedRow) => {
      const wpId = renderedRow.workPackageId;

      if (!wpId) {
        return;
      }
      const workPackageState:InputState<WorkPackageResource> = this.states.workPackages.get(wpId);
      const workPackage:WorkPackageResource|undefined = workPackageState.value;

      if (!workPackage) {
        return;
      }

      // We may still have a reference to a row that, e.g., just got deleted
      const startDate = workPackage.startDate ? moment(workPackage.startDate) : currentParams.now;
      const dueDate = workPackage.dueDate ? moment(workPackage.dueDate) : currentParams.now;
      const date = workPackage.date ? moment(workPackage.date) : currentParams.now;

      // start date
      newParams.dateDisplayStart = moment.min(
        newParams.dateDisplayStart,
        currentParams.now,
        startDate,
        date);

      // finish date
      newParams.dateDisplayEnd = moment.max(
        newParams.dateDisplayEnd,
        currentParams.now,
        dueDate,
        date);
    });

    // left spacing
    newParams.dateDisplayStart = newParams.dateDisplayStart.subtract(currentParams.dayCountForMarginLeft, 'days');

    // right spacing
    // RR: kept both variants for documentation purpose.
    // A: calculate the minimal width based on the width of the timeline view
    // B: calculate the minimal width based on the window width
    const width = this.$element.children().width()!; // A
    // const width = jQuery('body').width(); // B

    const pixelPerDay = currentParams.pixelPerDay;
    const visibleDays = Math.ceil((width / pixelPerDay) * 1.5);
    newParams.dateDisplayEnd = newParams.dateDisplayEnd.add(visibleDays, 'days');

    // Check if view params changed:

    // start date
    if (!newParams.dateDisplayStart.isSame(this._viewParameters.dateDisplayStart)) {
      changed = true;
      this._viewParameters.dateDisplayStart = newParams.dateDisplayStart;
    }

    // end date
    if (!newParams.dateDisplayEnd.isSame(this._viewParameters.dateDisplayEnd)) {
      changed = true;
      this._viewParameters.dateDisplayEnd = newParams.dateDisplayEnd;
    }

    // Calculate the visible viewport
    const firstDayInViewport = this.getFirstDayInViewport();
    const lastDayInViewport = this.getLastDayInViewport();
    const viewport:[Moment, Moment] = [firstDayInViewport, lastDayInViewport];
    this._viewParameters.visibleViewportAtCalculationTime = viewport;

    return changed;
  }

  private applyAutoZoomLevel() {
    if (this.workPackageIdOrder.length === 0) {
      return;
    }

    const workPackagesToCalculateWidthFrom =  this.getWorkPackagesToCalculateTimelineWidthFrom();
    const daysSpan = calculateDaySpan(workPackagesToCalculateWidthFrom, this.states.workPackages, this._viewParameters);
    const timelineWidthInPx = this.$element.parent().width()! - (2 * requiredPixelMarginLeft);

    for (const zoomLevel of zoomLevelOrder) {
      const pixelPerDay = getPixelPerDayForZoomLevel(zoomLevel);
      const visibleDays = timelineWidthInPx / pixelPerDay;

      if (visibleDays >= daysSpan || zoomLevel === _.last(zoomLevelOrder)) {
        // Zoom level is enough
        const previousZoomLevel = this._viewParameters.settings.zoomLevel;

        // did the zoom level changed?
        if (previousZoomLevel !== zoomLevel) {
          this._viewParameters.settings.zoomLevel = zoomLevel;
          this.wpTableComponent.timeline.scrollLeft = 0;
        }

        this.wpTableTimeline.appliedZoomLevel = zoomLevel;
        return;
      }
    }
  }

  setupManageCollapsedGroupHeaderCells() {
    this.workPackageViewCollapsedGroupsService.updates$()
      .pipe(
        this.commonPipes,
      )
      .subscribe((groupsCollapseEvent:IGroupsCollapseEvent) => {
        this.manageCollapsedGroupHeaderCells(
          groupsCollapseEvent,
                this.querySpace.results.value!.elements,
                this.collapsedGroupsCellsMap,
        );
      });
  }

  manageCollapsedGroupHeaderCells(groupsCollapseConfig:IGroupsCollapseEvent,
    tableWorkPackages:WorkPackageResource[],
    collapsedGroupsCellsMap:IGroupCellsMap) {
    const refreshAllGroupHeaderCells = groupsCollapseConfig.allGroupsChanged;
    const collapsedGroupsChange = groupsCollapseConfig.state;
    const collapsedGroupsChangeArray = Object.keys(collapsedGroupsChange);
    let groupsToUpdate:string[] = [];

    if (!collapsedGroupsChangeArray.length) {
      return;
    }

    if (refreshAllGroupHeaderCells) {
      groupsToUpdate = collapsedGroupsChangeArray.filter(groupIdentifier => this.shouldManageCollapsedGroupHeaderCells(groupIdentifier, groupsCollapseConfig));
    } else {
      const groupIdentifier = groupsCollapseConfig.lastChangedGroup!;
      if (this.shouldManageCollapsedGroupHeaderCells(groupIdentifier, groupsCollapseConfig)) {
        groupsToUpdate = [groupIdentifier];
      }
    }

    groupsToUpdate.forEach(groupIdentifier => {
      const groupIsCollapsed = collapsedGroupsChange[groupIdentifier];

      if (groupIsCollapsed) {
        this.createCollapsedGroupHeaderCells(groupIdentifier, tableWorkPackages, collapsedGroupsCellsMap);
      } else {
        this.removeCollapsedGroupHeaderCells(groupIdentifier, collapsedGroupsCellsMap);
      }
    });
  }

  shouldManageCollapsedGroupHeaderCells(groupIdentifier:string, groupsCollapseConfig:IGroupsCollapseEvent) {
    const keyGroupType = groupTypeFromIdentifier(groupIdentifier);

    return this.workPackageViewCollapsedGroupsService.groupTypesWithHeaderCellsWhenCollapsed.includes(keyGroupType) &&
          this.workPackageViewCollapsedGroupsService.groupTypesWithHeaderCellsWhenCollapsed.includes(groupsCollapseConfig.groupedBy!);
  }

  createCollapsedGroupHeaderCells(groupIdentifier:string, tableWorkPackages:WorkPackageResource[], collapsedGroupsCellsMap:IGroupCellsMap) {
    this.removeCollapsedGroupHeaderCells(groupIdentifier, collapsedGroupsCellsMap);

    const changedGroupId = groupIdFromIdentifier(groupIdentifier);
    const changedGroupType = groupTypeFromIdentifier(groupIdentifier);
    const changedGroupTableWorkPackages = tableWorkPackages.filter(tableWorkPackage => tableWorkPackage[changedGroupType].id === changedGroupId);
    const changedGroupWpsWithHeaderCells = changedGroupTableWorkPackages.filter(tableWorkPackage => this.shouldBeShownInCollapsedGroupHeaders(tableWorkPackage) &&
                                                                                                    (tableWorkPackage.date || tableWorkPackage.startDate));
    const changedGroupWpsWithHeaderCellsIds = changedGroupWpsWithHeaderCells.map(workPackage => workPackage.id!);

    this.collapsedGroupsCellsMap[groupIdentifier!] = this.cellsRenderer.buildCellsAndRenderOnRow(changedGroupWpsWithHeaderCellsIds, `group-${groupIdentifier}-timeline`, true);
  }

  removeCollapsedGroupHeaderCells(groupIdentifier:string, collapsedGroupsCellsMap:IGroupCellsMap) {
    if (collapsedGroupsCellsMap[groupIdentifier!]) {
      collapsedGroupsCellsMap[groupIdentifier!].forEach((cell:WorkPackageTimelineCell) => cell.clear());
      collapsedGroupsCellsMap[groupIdentifier!] = [];
    }
  }

  refreshCollapsedGroupsHeaderCells(collapsedGroupsCellsMap:IGroupCellsMap, cellsRenderer:WorkPackageTimelineCellsRenderer) {
    Object.keys(collapsedGroupsCellsMap).forEach(collapsedGroupKey => {
      const collapsedGroupCells = collapsedGroupsCellsMap[collapsedGroupKey];

      collapsedGroupCells.forEach(cell => cellsRenderer.refreshSingleCell(cell, false, true));
    });
  }

  shouldBeShownInCollapsedGroupHeaders(workPackage:WorkPackageResource) {
    return this.workPackageViewCollapsedGroupsService
      .wpTypesToShowInCollapsedGroupHeaders
      .some(wpTypeFunction => wpTypeFunction(workPackage));
  }

  getWorkPackagesToCalculateTimelineWidthFrom() {
    // Include work packages that are show in collapsed group
    // headers into the calculation, if not they could be rendered out
    // of the timeline (ie: milestones are shown on collapsed row groups).
    return [...this.workPackageIdOrder, ...this.workPackagesWithGroupHeaderCell];
  }
}
