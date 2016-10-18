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
import {WorkPackageTimelineService, RenderInfo, calculatePositionValueForDayCount} from "./wp-timeline.service";
import {WorkPackageResource} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {State} from "../../../helpers/reactive-fassade";
import {scopedObservable} from "../../../helpers/angular-rx-utils";
import IScope = angular.IScope;
import WorkPackage = op.WorkPackage;
import Observable = Rx.Observable;
import IDisposable = Rx.IDisposable;

export class WorkPackageTimelineCell {

  private wpState: State<WorkPackageResource>;

  private disposable: IDisposable;

  private bar: HTMLDivElement = null;

  private globalElements: {[type: string]: HTMLDivElement} = {};

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
        this.updateView(renderInfo);
      });
  }

  // TODO never called
  deactivate() {
    this.timelineCell.innerHTML = "";
    this.disposable && this.disposable.dispose();
  }

  private lazyInit() {
    if (this.bar === null) {
      this.bar = document.createElement("div");
      this.timelineCell.appendChild(this.bar);
    }
  }

  private updateView(renderInfo: RenderInfo) {
    // display bar
    this.lazyInit();
    const viewParams = renderInfo.viewParams;
    const wp = renderInfo.workPackage;

    // const cellHeight = jQuery(this.timelineCell).outerHeight();
    const start = moment(wp.startDate as any);
    const due = moment(wp.dueDate as any);

    // update global elements
    this.updateGlobalElements(renderInfo);

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

  private updateGlobalElements(renderInfo: RenderInfo) {
    const activeGlobalElementTypes = _.keys(renderInfo.globalElements);
    const knownGlobalElementTypes = _.keys(this.globalElements);

    const newGlobalElementTypes = _.difference(activeGlobalElementTypes, knownGlobalElementTypes);
    const removedGlobalElementTypes = _.difference(knownGlobalElementTypes, activeGlobalElementTypes);

    // new elements
    for (const newElem of newGlobalElementTypes) {
      const elem = document.createElement("div");
      this.timelineCell.appendChild(elem);
      this.globalElements[newElem] = elem;
    }

    // removed elements
    for (const removedElem of removedGlobalElementTypes) {
      this.globalElements[removedElem].remove();
    }

    // update elements
    for (const elemType of _.keys(renderInfo.globalElements)) {
      const elem = this.globalElements[elemType];
      const cellHeight = jQuery(this.timelineCell).outerHeight();
      elem.style.top = "-" + cellHeight + "px";
      elem.style.height = (cellHeight * 4) + "px";

      renderInfo.globalElements[elemType](renderInfo.workPackage, elem);
    }

  }

}
