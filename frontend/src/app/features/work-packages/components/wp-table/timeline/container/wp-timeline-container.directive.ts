//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  AfterViewInit,
  Component,
  ElementRef,
  Injector,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  IToast,
  ToastService,
} from 'core-app/shared/components/toaster/toast.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import * as moment from 'moment';
import { Moment } from 'moment';
import {
  filter,
  takeUntil,
  take,
} from 'rxjs/operators';
import {
  input,
  InputState,
} from '@openproject/reactivestates';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { WorkPackageTimelineCellsRenderer } from 'core-app/features/work-packages/components/wp-table/timeline/cells/wp-timeline-cells-renderer';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageTimelineCell } from 'core-app/features/work-packages/components/wp-table/timeline/cells/wp-timeline-cell';
import { selectorTimelineSide } from 'core-app/features/work-packages/components/wp-table/wp-table-scroll-sync';
import {
  debugLog,
  timeOutput,
} from 'core-app/shared/helpers/debug_output';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import {
  combineLatest,
  firstValueFrom,
  Observable,
} from 'rxjs';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WorkPackagesTableComponent } from 'core-app/features/work-packages/components/wp-table/wp-table.component';
import {
  groupIdFromIdentifier,
  groupTypeFromIdentifier,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-rows-helpers';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import {
  calculateDaySpan,
  getPixelPerDayForZoomLevel,
  requiredPixelMarginLeft,
  timelineElementCssClass,
  timelineHeaderSelector,
  timelineMarkerSelectionStartClass,
  TimelineViewParameters,
  zoomLevelOrder,
} from '../wp-timeline';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import * as Mousetrap from 'mousetrap';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';

@Component({
  selector: 'wp-timeline-container',
  templateUrl: './wp-timeline-container.html',
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

  private selectionParams:{ notification:IToast|null } = {
    notification: null,
  };

  private text:{ selectionMode:string };

  private refreshRequest = input<void>();

  private collapsedGroupsCellsMap:IGroupCellsMap = {};

  private orderedRows:RenderedWorkPackage[] = [];

  get commonPipes() {
    return (source:Observable<any>) => source.pipe(
      this.untilDestroyed(),
      takeUntil(this.querySpace.stopAllSubscriptions),
      filter(() => this.initialized && this.wpTableTimeline.isVisible),
    );
  }

  get workPackagesWithGroupHeaderCell():RenderedWorkPackage[] {
    const tableWorkPackages = this.querySpace.results.value!.elements;
    const wpsWithGroupHeaderCell = tableWorkPackages
      .filter((tableWorkPackage) => this.shouldBeShownInCollapsedGroupHeaders(tableWorkPackage))
      .map((tableWorkPackage) => tableWorkPackage.id);
    const workPackagesWithGroupHeaderCell = this.orderedRows.filter((row) => wpsWithGroupHeaderCell.includes(row.workPackageId) && !this.workPackageIdOrder.includes(row));

    return workPackagesWithGroupHeaderCell;
  }

  constructor(
    public readonly injector:Injector,
    private elementRef:ElementRef,
    private states:States,
    public wpTableComponent:WorkPackagesTableComponent,
    private toastService:ToastService,
    private wpTableTimeline:WorkPackageViewTimelineService,
    private notificationService:WorkPackageNotificationService,
    private wpRelations:WorkPackageRelationsService,
    private wpTableHierarchies:WorkPackageViewHierarchiesService,
    private halEvents:HalEventsService,
    private querySpace:IsolatedQuerySpace,
    readonly I18n:I18nService,
    private workPackageViewCollapsedGroupsService:WorkPackageViewCollapsedGroupsService,
    private weekdaysService:WeekdayService,
    private daysService:DayResourceService,
  ) {
    super();
  }

  ngAfterViewInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    const scrollBar = document.querySelector('.work-packages-tabletimeline--timeline-side');
    if (scrollBar) {
      scrollBar.addEventListener('scroll', () => {
        this.requireNonWorkingDays(this.getFirstDayInViewport().format('YYYY-MM-DD'), this.getLastDayInViewport().format('YYYY-MM-DD'));
      });
    }

    this.text = {
      selectionMode: this.I18n.t('js.gantt_chart.selection_mode.notification'),
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
      this.wpTableTimeline.live$(),
      this.weekdaysService.loadWeekdays(),
    ]).pipe(
      this.commonPipes,
    )
      .subscribe(([orderedRows]) => {
        // Remember all visible rows in their order of appearance.
        this.workPackageIdOrder = orderedRows.filter((row:RenderedWorkPackage) => !row.hidden);
        this.orderedRows = orderedRows;
        this.refreshView();
      });

    this.setupManageCollapsedGroupHeaderCells();
  }

  public nonWorkingDays:IDay[] = [];

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

    timeOutput('refreshView() in timeline container', async () => {
      // Reset the width of the outer container if its content shrinks
      this.outerContainer.css('width', 'auto');

      this.calculateViewParams(this._viewParameters);

      await this.requireNonWorkingDays(this.getFirstDayInViewport().format('YYYY-MM-DD'), this.getLastDayInViewport().format('YYYY-MM-DD'));

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
    this.activateSelectionMode(start.id!, (end) => {
      this.wpRelations
        .addCommonRelation(start.id!, 'follows', end.id!)
        .then(() => {
          this.halEvents.push(start, {
            eventType: 'association',
            relatedWorkPackage: end.id!,
            relationType: 'follows',
          });
        })
        .catch((error:any) => this.notificationService.handleRawError(error, end));
    });
  }

  startAddRelationFollower(start:WorkPackageResource) {
    this.activateSelectionMode(start.id!, (end) => {
      this.wpRelations
        .addCommonRelation(start.id!, 'precedes', end.id!)
        .then(() => {
          this.halEvents.push(start, {
            eventType: 'association',
            relatedWorkPackage: end.id!,
            relationType: 'precedes',
          });
        })
        .catch((error:any) => this.notificationService.handleRawError(error, end));
    });
  }

  getFirstDayInViewport() {
    const outerContainer = this.getParentScrollContainer();
    const { scrollLeft } = outerContainer;
    const nonVisibleDaysLeft = Math.floor(scrollLeft / this.viewParameters.pixelPerDay);
    return this.viewParameters.dateDisplayStart.clone().add(nonVisibleDaysLeft, 'days');
  }

  getLastDayInViewport() {
    const outerContainer = this.getParentScrollContainer();
    const { scrollLeft } = outerContainer;
    const width = outerContainer.offsetWidth;
    const viewPortRight = scrollLeft + width;
    const daysUntilViewPortEnds = Math.ceil(viewPortRight / this.viewParameters.pixelPerDay) + 1;
    return this.viewParameters.dateDisplayStart.clone().add(daysUntilViewPortEnds, 'days');
  }

  forceCursor(cursor:string) {
    jQuery(`.${timelineElementCssClass}`).css('cursor', cursor);
    jQuery('.wp-timeline-cell').css('cursor', cursor);
    jQuery('.hascontextmenu').css('cursor', cursor);
    jQuery('.leftHandle').css('cursor', cursor);
    jQuery('.rightHandle').css('cursor', cursor);
  }

  resetCursor() {
    jQuery(`.${timelineElementCssClass}`).css('cursor', '');
    jQuery('.wp-timeline-cell').css('cursor', '');
    jQuery('.hascontextmenu').css('cursor', '');
    jQuery('.leftHandle').css('cursor', '');
    jQuery('.rightHandle').css('cursor', '');
  }

  private resetSelectionMode() {
    this._viewParameters.activeSelectionMode = null;
    this._viewParameters.selectionModeStart = null;

    if (this.selectionParams.notification) {
      this.toastService.remove(this.selectionParams.notification);
    }

    Mousetrap.unbind('esc');

    this.$element.removeClass('active-selection-mode');
    jQuery(`.${timelineMarkerSelectionStartClass}`).removeClass(timelineMarkerSelectionStartClass);
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
    this.selectionParams.notification = this.toastService.addNotice(this.text.selectionMode);

    this.$element.addClass('active-selection-mode');

    this.refreshView();
  }

  async requireNonWorkingDays(start:Date|string, end:Date|string) {
    this.nonWorkingDays = await firstValueFrom(
      this
        .daysService
        .requireNonWorkingYears$(start, end)
        .pipe(take(1)),
    );
  }

  isNonWorkingDay(date:Date|string):boolean {
    const formatted = moment(date).format('YYYY-MM-DD');
    return (this.nonWorkingDays.findIndex((el) => el.date === formatted) !== -1);
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
        date,
      ).clone(); // clone because currentParams.now should not be changed

      // finish date
      newParams.dateDisplayEnd = moment.max(
        newParams.dateDisplayEnd,
        currentParams.now,
        dueDate,
        date,
      ).clone(); // clone because currentParams.now should not be changed
    });

    // left spacing
    newParams.dateDisplayStart.subtract(currentParams.dayCountForMarginLeft, 'days'); // .substract modifies its instance

    // right spacing
    // RR: kept both variants for documentation purpose.
    // A: calculate the minimal width based on the width of the timeline view
    // B: calculate the minimal width based on the window width
    const width = this.$element.children().width()!; // A
    // const width = jQuery('body').width(); // B

    const { pixelPerDay } = currentParams;
    const visibleDays = Math.ceil((width / pixelPerDay) * 1.5);
    newParams.dateDisplayEnd.add(visibleDays, 'days'); // .add modifies its instance

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

    const workPackagesToCalculateWidthFrom = this.getWorkPackagesToCalculateTimelineWidthFrom();
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
      groupsToUpdate = collapsedGroupsChangeArray.filter((groupIdentifier) => this.shouldManageCollapsedGroupHeaderCells(groupIdentifier, groupsCollapseConfig));
    } else {
      const groupIdentifier = groupsCollapseConfig.lastChangedGroup!;
      if (this.shouldManageCollapsedGroupHeaderCells(groupIdentifier, groupsCollapseConfig)) {
        groupsToUpdate = [groupIdentifier];
      }
    }

    groupsToUpdate.forEach((groupIdentifier) => {
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

    return this.workPackageViewCollapsedGroupsService.groupTypesWithHeaderCellsWhenCollapsed.includes(keyGroupType)
      && this.workPackageViewCollapsedGroupsService.groupTypesWithHeaderCellsWhenCollapsed.includes(groupsCollapseConfig.groupedBy!);
  }

  createCollapsedGroupHeaderCells(groupIdentifier:string, tableWorkPackages:WorkPackageResource[], collapsedGroupsCellsMap:IGroupCellsMap) {
    this.removeCollapsedGroupHeaderCells(groupIdentifier, collapsedGroupsCellsMap);

    const changedGroupId = groupIdFromIdentifier(groupIdentifier);
    const changedGroupType = groupTypeFromIdentifier(groupIdentifier);
    const changedGroupTableWorkPackages = tableWorkPackages.filter((tableWorkPackage) => tableWorkPackage[changedGroupType].id === changedGroupId);
    const changedGroupWpsWithHeaderCells = changedGroupTableWorkPackages.filter((tableWorkPackage) => this.shouldBeShownInCollapsedGroupHeaders(tableWorkPackage)
      && (tableWorkPackage.date || tableWorkPackage.startDate));
    const changedGroupWpsWithHeaderCellsIds = changedGroupWpsWithHeaderCells.map((workPackage) => workPackage.id!);

    this.collapsedGroupsCellsMap[groupIdentifier] = this.cellsRenderer.buildCellsAndRenderOnRow(changedGroupWpsWithHeaderCellsIds, `group-${groupIdentifier}-timeline`, true);
  }

  removeCollapsedGroupHeaderCells(groupIdentifier:string, collapsedGroupsCellsMap:IGroupCellsMap) {
    if (collapsedGroupsCellsMap[groupIdentifier]) {
      collapsedGroupsCellsMap[groupIdentifier].forEach((cell:WorkPackageTimelineCell) => cell.clear());
      collapsedGroupsCellsMap[groupIdentifier] = [];
    }
  }

  refreshCollapsedGroupsHeaderCells(collapsedGroupsCellsMap:IGroupCellsMap, cellsRenderer:WorkPackageTimelineCellsRenderer) {
    Object.keys(collapsedGroupsCellsMap).forEach((collapsedGroupKey) => {
      const collapsedGroupCells = collapsedGroupsCellsMap[collapsedGroupKey];

      collapsedGroupCells.forEach((cell) => cellsRenderer.refreshSingleCell(cell, false, true));
    });
  }

  shouldBeShownInCollapsedGroupHeaders(workPackage:WorkPackageResource) {
    return this.workPackageViewCollapsedGroupsService
      .wpTypesToShowInCollapsedGroupHeaders
      .some((wpTypeFunction) => wpTypeFunction(workPackage));
  }

  getWorkPackagesToCalculateTimelineWidthFrom() {
    // Include work packages that are show in collapsed group
    // headers into the calculation, if not they could be rendered out
    // of the timeline (ie: milestones are shown on collapsed row groups).
    return [...this.workPackageIdOrder, ...this.workPackagesWithGroupHeaderCell];
  }
}
