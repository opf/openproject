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


export class TimelineViewParameters {
  dateDisplayStart: Moment = moment({hour: 0, minute: 0, seconds: 0});
  dateDisplayEnd: Moment = this.dateDisplayStart;
  pixelPerDay = 10;
}

export interface RenderInfo {
  viewParams: TimelineViewParameters;
  workPackage: WorkPackage;
}

export class WorkPackageTimelineService {

  private _viewParameters: TimelineViewParameters = new TimelineViewParameters();

  private workPackagesInView: {[id: string]: WorkPackage} = {};

  private viewParamsSubject = new Rx.BehaviorSubject<TimelineViewParameters>(new TimelineViewParameters());

  constructor(private states: States) {
    "ngInject";
  }

  get viewParameters() {
    return this._viewParameters;
  }

  addWorkPackage(wpId: string): Rx.Observable<RenderInfo> {
    return Rx.Observable
      .combineLatest(
        this.viewParamsSubject,
        this.states.workPackages.get(wpId).observe(null),
        (vp: TimelineViewParameters, wp: any) => {
          return {
            viewParams: vp,
            workPackage: wp
          };
        }
      )
      .flatMap(renderInfo => {
        const wp = renderInfo.workPackage;
        this.workPackagesInView[wp.id] = wp;

        const viewParamsChanged = this.calculateViewParams();
        if (viewParamsChanged) {
          // view params have changed, notify all cells
          this.viewParamsSubject.onNext(this._viewParameters);
          return Observable.empty<RenderInfo>();
        } else {
          // view params have not changed, only notify this observer
          return Observable.just(renderInfo);
        }
      });
  
  }

  private calculateViewParams(): boolean {
    let changed = false;
    const newParams = new TimelineViewParameters();

    // Calculate view parameters
    for (const wpId in this.workPackagesInView) {
      const workPackage = this.workPackagesInView[wpId];

      if (workPackage.startDate && workPackage.dueDate) {
        const start = moment(workPackage.startDate as any);
        const due = moment(workPackage.dueDate as any);

        // start date
        if (start.isBefore(newParams.dateDisplayStart)) {
          newParams.dateDisplayStart = start;
        }

        // due date
        if (due.isAfter(newParams.dateDisplayEnd)) {
          newParams.dateDisplayEnd = due;
        }
      }
    }

    // Check if view params changed:

    // start date
    if (!this._viewParameters.dateDisplayStart.isSame(newParams.dateDisplayStart)) {
      changed = true;
      this._viewParameters.dateDisplayStart = newParams.dateDisplayStart;
    }

    // end date
    if (!this._viewParameters.dateDisplayEnd.isSame(newParams.dateDisplayEnd)) {
      changed = true;
      this._viewParameters.dateDisplayEnd = newParams.dateDisplayEnd;
    }

    return changed;
  }
}


openprojectModule.service("workPackageTimelineService", WorkPackageTimelineService);
