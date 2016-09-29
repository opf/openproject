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

import {States} from "../../states.service";
import {WorkPackageTimelineService, TimelineViewParameters} from "./wp-timeline.service";
import {WorkPackageResource} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {State} from "../../../helpers/reactive-fassade";
import IScope = angular.IScope;
import WorkPackage = op.WorkPackage;
import Observable = Rx.Observable;

export class WorkPackageTimelineCell {

  private state: State<WorkPackageResource>;

  private bar: HTMLDivElement;

  constructor(private workPackageTimelineService: WorkPackageTimelineService,
              private scope: IScope,
              private states: States,
              private workPackageId: string,
              private timelineCell: HTMLTableElement) {

    this.state = this.states.workPackages.get(this.workPackageId);
  }

  render() {
    this.bar = document.createElement("div");
    this.timelineCell.appendChild(this.bar);

    Observable.combineLatest(
      this.workPackageTimelineService.viewParameters$,
      this.state.observe(this.scope),
      (viewParams, workPackage) => {
        return {vp: viewParams, wp: workPackage};
      })
      .subscribe(result => {
        this.update(result.vp, <any> result.wp);
      });

    this.state.get().then((wp: any) => {
      this.workPackageTimelineService.addWorkPackageToView(wp);
    });


  }

  update(viewParams: TimelineViewParameters, workPackage: WorkPackage) {
    console.log("update");
    // console.log(wp.startDate);

    this.bar.style.width = "1000px";
    this.bar.style.height = "1em";
    this.bar.style.backgroundColor = "#FF0000";

  }

}
