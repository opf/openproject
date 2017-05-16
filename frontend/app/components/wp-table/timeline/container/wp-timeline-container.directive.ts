// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++
import {BehaviorSubject, Observable} from "rxjs";
import {openprojectModule} from "../../../../angular-modules";
import {scopeDestroyed$} from "../../../../helpers/angular-rx-utils";
import {debugLog} from "../../../../helpers/debug_output";
import {TypeResource} from "../../../api/api-v3/hal-resources/type-resource.service";
import {WorkPackageResourceInterface} from "../../../api/api-v3/hal-resources/work-package-resource.service";
import {States} from "../../../states.service";
import {WorkPackageNotificationService} from "../../../wp-edit/wp-notification.service";
import {WorkPackageTableTimelineService} from "../../../wp-fast-table/state/wp-table-timeline.service";
import {WorkPackageTableTimelineState} from "../../../wp-fast-table/wp-table-timeline";
import {WorkPackageRelationsService} from "../../../wp-relations/wp-relations.service";
import {WorkPackagesTableController} from "../../wp-table.directive";
import {RenderInfo, timelineMarkerSelectionStartClass, TimelineViewParameters} from "../wp-timeline";
import {WorkPackageTimelineCell} from "../wp-timeline-cell";
import IDirective = angular.IDirective;
import IScope = angular.IScope;
import {WorkPackageTable} from '../../../wp-fast-table/wp-fast-table';
import {WorkPackageTableHierarchiesService} from '../../../wp-fast-table/state/wp-table-hierarchy.service.ts';

export class WorkPackageTimelineTableController {

  public wpTableDirective: WorkPackagesTableController;

  public workPackageTable: WorkPackageTable;

  private _viewParameters: TimelineViewParameters = new TimelineViewParameters();

  private workPackagesInView: {[id: string]: WorkPackageResourceInterface} = {};

  private updateAllWorkPackagesSubject = new BehaviorSubject<boolean>(true);

  public disableViewParamsCalculation = false;

  public cells:{[id: string]:WorkPackageTimelineCell} = {};

  private renderers:{ [name:string]: (vp:TimelineViewParameters) => void } = {};

  constructor(private $scope:IScope,
              private $element:ng.IAugmentedJQuery,
              private states:States,
              private wpTableTimeline:WorkPackageTableTimelineService,
              private wpNotificationsService:WorkPackageNotificationService,
              private wpRelations:WorkPackageRelationsService,
              private wpTableHierarchies:WorkPackageTableHierarchiesService) {

    "ngInject";
  }

  $onInit() {
    // Register this instance to the table
    this.wpTableDirective.registerTimeline(this, this.timelineBody[0]);

    // Refresh timeline view after table rendered
    this.states.table.rendered.values$()
      .take(1)
      .subscribe(() => this.refreshView());

    // Refresh timeline view when becoming visible
    this.states.table.timelineVisible.values$()
      .filter((timelineState:WorkPackageTableTimelineState) => timelineState.isVisible)
      .takeUntil(scopeDestroyed$(this.$scope))
      .subscribe((timelineState:WorkPackageTableTimelineState) => {
        this.viewParameters.settings.zoomLevel =  timelineState.zoomLevel;
        this.refreshView();
      });

    // Load the types whenever the timeline is first visible
    // TODO: Load only necessary types from API
    this.states.table.timelineVisible.values$()
      .filter((timelineState) => timelineState.isVisible)
      .take(1)
      .subscribe(() => {
        TypeResource.loadAll().then(() => {
          this.refreshView();
        });
      });
  }

  onRefreshRequested(name:string, callback:(vp:TimelineViewParameters) => void) {
    this.renderers[name] = callback;
  }

  public updateWorkPackageInfo(cell: WorkPackageTimelineCell) {
    this.cells[cell.latestRenderInfo.workPackage.id] = cell;
    this.refreshView();
  }

  public removeWorkPackageInfo(id: string) {
    delete this.cells[id];
    this.refreshView();
  }

  getAbsoluteLeftCoordinates():number {
    return this.$element.offset().left;
  }

  get viewParameters(): TimelineViewParameters {
    return this._viewParameters;
  }

  get viewParameterSettings() {
    return this._viewParameters.settings;
  }

  get timelineBody():ng.IAugmentedJQuery {
    return this.$element.find('.wp-table-timeline--body');
  }

  get inHierarchyMode():boolean {
    return this.wpTableHierarchies.isEnabled;
  }

  refreshView() {
    if (!this.wpTableTimeline.isVisible) {
      debugLog("refreshView() requested, but TL is invisible.");
      return;
    }

    debugLog("refreshView() in timeline container");
    this.calculateViewParams(this._viewParameters);
    this.updateAllWorkPackagesSubject.next(true);

    _.each(this.renderers, (cb, key) => {
      debugLog(`Refreshing timeline member ${key}`);
      cb(this._viewParameters);
    });
  }

  addWorkPackage(wpId: string): Observable<RenderInfo> {
    const wpObs = this.states.workPackages.get(wpId).values$()
      .takeUntil(scopeDestroyed$(this.$scope))
      .map((wp: any) => {
        this.workPackagesInView[wp.id] = wp;
        const viewParamsChanged = this.calculateViewParams(this._viewParameters);
        if (viewParamsChanged) {
          this.refreshView();
        }

        return {
          viewParams: this._viewParameters,
          workPackage: wp
        };
      })
      .distinctUntilChanged((v1, v2) => {
        return v1 === v2;
      }, renderInfo => {
        return ""
          + renderInfo.viewParams.dateDisplayStart
          + renderInfo.viewParams.dateDisplayEnd
          + renderInfo.workPackage.date
          + renderInfo.workPackage.startDate
          + renderInfo.workPackage.dueDate;
      });

    return Observable.combineLatest(
        wpObs,
        this.updateAllWorkPackagesSubject,
        (renderInfo: RenderInfo) => {
          return renderInfo;
        }
      );
  }

  startAddRelationPredecessor(start: WorkPackageResourceInterface) {
    this.activateSelectionMode(start.id, end => {
      this.wpRelations
        .addCommonRelation(start as any, "follows", end.id)
        .catch((error:any) => this.wpNotificationsService.handleErrorResponse(error, end));
    });
  }

  startAddRelationFollower(start: WorkPackageResourceInterface) {
    this.activateSelectionMode(start.id, end => {
      this.wpRelations
        .addCommonRelation(start as any, "precedes", end.id)
        .catch((error:any) => this.wpNotificationsService.handleErrorResponse(error, end));
    });
  }

  private activateSelectionMode(start: string, callback: (wp: WorkPackageResourceInterface) => any) {
    start = start.toString(); // old system bug: ID can be a 'number'

    this._viewParameters.activeSelectionMode = (wp: WorkPackageResourceInterface) => {
      callback(wp);

      this._viewParameters.activeSelectionMode = null;
      this._viewParameters.selectionModeStart = null;

      this.$element.removeClass("active-selection-mode");
      jQuery("." + timelineMarkerSelectionStartClass).removeClass(timelineMarkerSelectionStartClass);
      this.refreshView();
    };
    this._viewParameters.selectionModeStart = start;

    this.$element.addClass("active-selection-mode");
    this.refreshView();
  }

  private calculateViewParams(currentParams: TimelineViewParameters): boolean {
    if (this.disableViewParamsCalculation) {
      return false;
    }

    const newParams = new TimelineViewParameters();
    let changed = false;

    // Calculate view parameters
    for (const wpId in this.workPackagesInView) {
      const workPackage = this.workPackagesInView[wpId];

      const startDate = workPackage.startDate ? moment(workPackage.startDate) : currentParams.now;
      const dueDate = workPackage.dueDate ? moment(workPackage.dueDate) : currentParams.now;
      const date = workPackage.date ? moment(workPackage.date) : currentParams.now;

      // start date
      newParams.dateDisplayStart = moment.min(
        newParams.dateDisplayStart,
        currentParams.now,
        startDate,
        date);

      // due date
      newParams.dateDisplayEnd = moment.max(
        newParams.dateDisplayEnd,
        currentParams.now,
        dueDate,
        date);
    }

    // left spacing
    newParams.dateDisplayStart.subtract(3, "days");

    // right spacing
    const width = this.$element.width();
    const pixelPerDay = currentParams.pixelPerDay;
    const visibleDays = Math.ceil((width / pixelPerDay) * 1.5);
    newParams.dateDisplayEnd.add(visibleDays, "days");

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

    return changed;
  }
}

openprojectModule.component("wpTimelineContainer", {
  controller: WorkPackageTimelineTableController,
  templateUrl:  '/components/wp-table/timeline/container/wp-timeline-container.html',
  require: {
    wpTableDirective: '^wpTable'
  }
});
