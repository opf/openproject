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

export class TimelineViewParameters {
  dateDisplayStart: number;
  dateDisplayEnd: number;
}

export interface RenderInfo {
  viewParams: TimelineViewParameters;
  workPackage: WorkPackage;
}

export class WorkPackageTimelineService {

  private timelineViewParameters: TimelineViewParameters = new TimelineViewParameters();

  private workPackagesInView: {[id: string]: WorkPackage} = {};

  private viewParamsSubject = new Rx.BehaviorSubject<TimelineViewParameters>(new TimelineViewParameters());

  constructor(private states: States) {
    "ngInject";
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

        const oldParams = this.timelineViewParameters;
        const newParams = this.calculateViewParams();

        if (!_.isEqual(oldParams, newParams)) {
          // view params have changed, notify all cells
          this.viewParamsSubject.onNext(newParams);
          return Observable.empty<RenderInfo>();
        } else {
          // view params have not changed, only notify this observer
          return Observable.just(renderInfo);
        }
      });
  }

  private calculateViewParams(): TimelineViewParameters {
    const params = new TimelineViewParameters();

    for (const wpId in this.workPackagesInView) {
      const wp = this.workPackagesInView[wpId];
      const start = wp.startDate ? new Date(wp.startDate as any).getTime() : null;
      const due = wp.dueDate ? new Date(wp.dueDate as any).getTime() : null;

      // if (!params.dateDisplayStart || (start && start < params.dateDisplayStart)) {
      //   params.dateDisplayStart = start;
      // }
      // if (!params.dateDisplayEnd || (due && due < params.dateDisplayEnd)) {
      //   params.dateDisplayEnd = due;
      // }

    }

    return params;
  }
}


openprojectModule.service("workPackageTimelineService", WorkPackageTimelineService);
