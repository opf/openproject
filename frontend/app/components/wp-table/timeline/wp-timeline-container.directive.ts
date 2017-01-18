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
import {openprojectModule} from "../../../angular-modules";
import {TimelineViewParameters, RenderInfo, timelineElementCssClass} from "./wp-timeline";
import {WorkPackageResourceInterface} from "./../../api/api-v3/hal-resources/work-package-resource.service";
import {InteractiveTableController} from "./../../common/interactive-table/interactive-table.directive";
import {WpTimelineHeader} from "./wp-timeline.header";
import {States} from "./../../states.service";
import {BehaviorSubject, Observable} from "rxjs";

import Moment = moment.Moment;
import IDirective = angular.IDirective;
import IScope = angular.IScope;

export class WorkPackageTimelineTableController {

  private _viewParameters: TimelineViewParameters = new TimelineViewParameters();

  private workPackagesInView: {[id: string]: WorkPackageResourceInterface} = {};

  public wpTimelineHeader: WpTimelineHeader;

  private updateAllWorkPackagesSubject = new BehaviorSubject<boolean>(true);

  private refreshViewRequested = false;

  public visible = false;

  public disableViewParamsCalculation = false;

  constructor(private $element: ng.IAugmentedJQuery,
              private TypeResource,
              private states: States) {

    "ngInject";

    this.wpTimelineHeader = new WpTimelineHeader(this);
    $element.on(InteractiveTableController.eventName, () => {
      this.refreshView();
    });

    // TODO: Load only necessary types from API
    TypeResource.loadAll();
  }

  /**
   * Toggle whether this instance is currently showing.
   */
  public toggle() {
    this.visible = !this.visible;

    // If hiding view, resize table afterwards
    if (!this.visible) {
      jQuery(window).trigger('resize');
    }
  }

  /**
   * Returns a defensive copy of the currently used view parameters.
   */
  getViewParametersCopy(): TimelineViewParameters {
    return _.cloneDeep(this._viewParameters);
  }

  get viewParameterSettings() {
    return this._viewParameters.settings;
  }

  refreshView() {
    if (!this.refreshViewRequested) {
      setTimeout(() => {
        this.calculateViewParams(this._viewParameters);
        this.updateAllWorkPackagesSubject.next(true);
        this.wpTimelineHeader.refreshView(this._viewParameters);
        this.refreshScrollOnly();
        this.refreshViewRequested = false;
      }, 30);
    }
    this.refreshViewRequested = true;
  }

  refreshScrollOnly() {
    jQuery("." + timelineElementCssClass).css("margin-left", this._viewParameters.scrollOffsetInPx + "px");
  }

  addWorkPackage(wpId: string): Observable<RenderInfo> {
    // console.log("addWorkPackage() = " + wpId);

    const wpObs = this.states.workPackages.get(wpId).observe(null)
      .map((wp: any) => {
        this.workPackagesInView[wp.id] = wp;
        const viewParamsChanged = this.calculateViewParams(this._viewParameters);
        if (viewParamsChanged) {
          // view params have changed, notify all cells
          this.refreshView();
        }

        return {
          viewParams: this._viewParameters,
          workPackage: wp
        };
      });

    return Observable.combineLatest(
        wpObs,
        this.updateAllWorkPackagesSubject,
        (renderInfo, forceUpdate) => {
          return renderInfo;
        }
      );
  }

  private calculateViewParams(currentParams: TimelineViewParameters): boolean {
    if (this.disableViewParamsCalculation) {
      return false;
    }

    // console.log("calculateViewParams()");

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
    const headerWidth = this.wpTimelineHeader.getHeaderWidth();
    const pixelPerDay = currentParams.pixelPerDay;
    const visibleDays = Math.ceil((headerWidth / pixelPerDay) * 1.5);
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

    // console.log("        changed=" + changed);

    return changed;
  }
}


function wpTimelineContainer() {
  return {
    restrict: 'A',
    controller: WorkPackageTimelineTableController,
    bindToController: true
  };
};

openprojectModule.directive('wpTimelineContainer', wpTimelineContainer);
