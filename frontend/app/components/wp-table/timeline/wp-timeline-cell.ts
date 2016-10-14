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
import {scopedObservable} from "../../../helpers/angular-rx-utils";
import IScope = angular.IScope;
import WorkPackage = op.WorkPackage;
import Observable = Rx.Observable;
import IDisposable = Rx.IDisposable;

function calculatePositionValueForDayCount(viewParams: TimelineViewParameters, days: number): string {
  const daysInPx = days * viewParams.pixelPerDay;
  if (viewParams.showDurationInPx) {
    return daysInPx + "px";
  } else {
    return (daysInPx / viewParams.maxWidthInPx * 100) + "%";
  }
}

export class WorkPackageTimelineCell {

  private wpState: State<WorkPackageResource>;

  private disposable: IDisposable;

  private bar: HTMLDivElement = null;

  private today: HTMLDivElement;

  constructor(private workPackageTimelineService: WorkPackageTimelineService,
              private scope: IScope,
              private states: States,
              private workPackageId: string,
              private timelineCell: HTMLTableElement) {

    this.wpState = this.states.workPackages.get(this.workPackageId);
  }

  activate() {
    scopedObservable(
      this.scope,
      this.workPackageTimelineService.addWorkPackage(this.workPackageId))
      .subscribe(renderInfo => {
        this.updateView(renderInfo.viewParams, renderInfo.workPackage);
      });
  }

  deactivate() {
    this.timelineCell.innerHTML = "";
    this.disposable && this.disposable.dispose();
  }

  private lazyInit() {
    if (this.bar === null) {
      this.today = document.createElement("div");
      this.timelineCell.appendChild(this.today);
    }

    if (this.bar === null) {
      this.bar = document.createElement("div");
      this.timelineCell.appendChild(this.bar);
    }
  }

  private updateView(viewParams: TimelineViewParameters, wp: WorkPackage) {
    this.lazyInit();

    const cellHeight = jQuery(this.timelineCell).outerHeight();
    const start = moment(wp.startDate as any);
    const due = moment(wp.dueDate as any);

    // general settings - today
    this.today.style.position = "absolute";
    this.today.style.width = "2px";
    this.today.style.borderLeft = "2px dotted red";
    this.today.style.zIndex = "10";

    this.today.style.top = "-" + cellHeight + "px";
    this.today.style.height = (cellHeight * 4) + "px";
    const offsetToday = viewParams.now.diff(viewParams.dateDisplayStart, "days");
    this.today.style.left = calculatePositionValueForDayCount(viewParams, offsetToday);


    // abort if no start or due date
    if (!wp.startDate || !wp.dueDate) {
      return;
    }


    // general settings - bar
    this.bar.style.position = "relative";
    this.bar.style.height = "1em";
    this.bar.style.backgroundColor = "#8CD1E8";
    this.bar.style.borderRadius = "5px";
    this.bar.style.cssFloat = "left";

    // offset left
    const offsetStart = start.diff(viewParams.dateDisplayStart, "days");
    this.bar.style.left = calculatePositionValueForDayCount(viewParams, offsetStart);

    // duration
    const duration = due.diff(start, "days");
    this.bar.style.width = calculatePositionValueForDayCount(viewParams, duration);

  }

}
