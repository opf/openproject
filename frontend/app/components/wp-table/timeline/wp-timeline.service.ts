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
import {States} from "../../states.service";
import WorkPackage = op.WorkPackage;
import Observable = Rx.Observable;
import Moment = moment.Moment;

export const timelineElementCssClass = "timeline-element";

/**
 *
 */
export class TimelineViewParametersSettings {

  showDurationInPx = true;

  pixelPerDay = 10;

  scrollOffsetInDays = 0;

}

/**
 *
 */
export class TimelineViewParameters {

  readonly now: Moment = moment({hour: 0, minute: 0, seconds: 0});

  dateDisplayStart: Moment = moment({hour: 0, minute: 0, seconds: 0});

  dateDisplayEnd: Moment = this.dateDisplayStart.clone().add(1, "day");

  settings: TimelineViewParametersSettings = new TimelineViewParametersSettings();

  get maxWidthInPx() {
    return this.dateDisplayEnd.diff(this.dateDisplayStart, "days") * this.settings.pixelPerDay;
  }

  get scrollOffsetInPx() {
    return this.settings.scrollOffsetInDays * this.settings.pixelPerDay;
  }

}

/**
 *
 */
export interface RenderInfo {
  viewParams: TimelineViewParameters;
  workPackage: WorkPackage;
  globalElements: GlobalElementsRegistry;
}

/**
 *
 * @param viewParams
 * @param days
 * @returns {string}
 */
export function calculatePositionValueForDayCount(viewParams: TimelineViewParameters, days: number): string {
  const daysInPx = days * viewParams.settings.pixelPerDay;
  if (viewParams.settings.showDurationInPx) {
    return daysInPx + "px";
  } else {
    return (daysInPx / viewParams.maxWidthInPx * 100) + "%";
  }
}

type GlobalElementsRegistry = {[type: string]: (renderInfo: RenderInfo, elem: HTMLDivElement) => any};

/**
 *
 */
export class WorkPackageTimelineService {

  private _viewParameters: TimelineViewParameters = new TimelineViewParameters();

  private workPackagesInView: {[id: string]: WorkPackage} = {};

  private globalElementsRegistry: GlobalElementsRegistry = {};

  private updateAllWorkPackagesSubject = new Rx.BehaviorSubject<boolean>(true);

  private refreshViewRequested = false;

  constructor(private states: States) {
    "ngInject";

    // Today Line
    this.globalElementsRegistry["today"] = (renderInfo: RenderInfo, elem: HTMLDivElement) => {
      elem.style.position = "absolute";
      elem.style.width = "2px";
      elem.style.borderLeft = "2px solid red";
      elem.style.zIndex = "10";
      const offsetToday = this._viewParameters.now.diff(renderInfo.viewParams.dateDisplayStart, "days");
      elem.style.left = calculatePositionValueForDayCount(renderInfo.viewParams, offsetToday);
      elem.style.marginLeft = renderInfo.viewParams.scrollOffsetInPx + "px";
    };
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
        this.updateAllWorkPackagesSubject.onNext(true);
        this.refreshViewRequested = false;
      }, 30);
    }
    this.refreshViewRequested = true;
  }

  refreshScrollOnly() {
    // console.log("setScrollValue() " + this._viewParameters.scrollOffsetInPx);
    jQuery(".timeline-element").css("margin-left", this._viewParameters.scrollOffsetInPx + "px");
  }


  addWorkPackage(wpId: string): Rx.Observable<RenderInfo> {
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
          workPackage: wp,
          globalElements: this.globalElementsRegistry
        };
      });

    return Rx.Observable
      .combineLatest(
        wpObs,
        this.updateAllWorkPackagesSubject,
        (renderInfo, forceUpdate) => {
          return renderInfo;
        }
      );

    // const obs = Rx.Observable
    //   .combineLatest(
    //     this.updateAllWorkPackagesSubject,
    //     this.states.workPackages.get(wpId).observe(null),
    //     (vp: boolean, wp: any) => {
    //       return {
    //         viewParams: this._viewParameters,
    //         workPackage: wp,
    //         globalElements: this.globalElementsRegistry
    //       };
    //     }
    //   )
    //   .flatMap(renderInfo => {
    //     const wp = renderInfo.workPackage;
    //     this.workPackagesInView[wp.id] = wp;
    //
    //     console.log("    flatMap = " + wpId);
    // const viewParamsChanged = this.calculateViewParams(renderInfo.viewParams);

    // if (viewParamsChanged) {
    // view params have changed, notify all cells
    // this.viewParamsSubject.onNext(this._viewParameters);
    // this.refreshView();
    // return Observable.empty<RenderInfo>();
    // } else {
    // view params have not changed, only notify this observer
    // console.log("    update wp=" + wpId);
    // return Observable.just(renderInfo);
    // }
    // });

    // return obs;
  }

  private calculateViewParams(currentParams: TimelineViewParameters): boolean {
    console.log("calculateViewParams()");

    const newParams = new TimelineViewParameters();
    let changed = false;

    // Calculate view parameters
    for (const wpId in this.workPackagesInView) {
      const workPackage = this.workPackagesInView[wpId];

      if (workPackage.startDate && workPackage.dueDate) {
        const start = moment(workPackage.startDate as any);
        const due = moment(workPackage.dueDate as any);

        // start date
        newParams.dateDisplayStart = moment.min(
          newParams.dateDisplayStart,
          // currentParams.dateDisplayStart,
          currentParams.now,
          start);

        // due date
        newParams.dateDisplayEnd = moment.max(
          newParams.dateDisplayEnd,
          // currentParams.dateDisplayEnd,
          currentParams.now,
          due);
      }
    }

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

openprojectModule.service("workPackageTimelineService", WorkPackageTimelineService);
