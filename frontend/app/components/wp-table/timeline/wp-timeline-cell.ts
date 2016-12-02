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
import {timelineElementCssClass, RenderInfo, calculatePositionValueForDayCount} from "./wp-timeline";
import {WorkPackageTimelineTableController} from "./wp-timeline-container.directive";
import {WorkPackageCacheService} from "../../work-packages/work-package-cache.service";
import IScope = angular.IScope;
import WorkPackage = op.WorkPackage;
import Observable = Rx.Observable;
import IDisposable = Rx.IDisposable;
import Moment = moment.Moment;

const classNameLeftHandle = "leftHandle";
const classNameRightHandle = "rightHandle";

export class WorkPackageTimelineCell {

  private disposable: IDisposable;

  private bar: HTMLDivElement = null;

  constructor(private workPackageTimeline: WorkPackageTimelineTableController,
              private wpCacheService: WorkPackageCacheService,
              private scope: IScope,
              private states: States,
              private workPackageId: string,
              private timelineCell: HTMLElement) {
  }

  activate() {
    this.disposable = this.workPackageTimeline.addWorkPackage(this.workPackageId)
      .subscribe(renderInfo => {
        this.updateView(renderInfo);
      });
  }

  // TODO never called so far
  deactivate() {
    this.timelineCell.innerHTML = "";
    this.disposable && this.disposable.dispose();
  }

  private lazyInit(renderInfo: RenderInfo) {
    if (this.bar === null) {
      this.bar = document.createElement("div");
      this.bar.className = timelineElementCssClass;
      this.timelineCell.appendChild(this.bar);
      this.registerMouseHandler(renderInfo);

      const left = document.createElement("div");
      left.className = classNameLeftHandle;
      left.style.position = "absolute";
      // left.style.backgroundColor = "#9c00ff";
      left.style.left = "0px";
      left.style.top = "0px";
      left.style.width = "20px";
      left.style.maxWidth = "20%";
      left.style.height = "100%";
      left.style.cursor = "w-resize";
      this.bar.appendChild(left);

      const right = document.createElement("div");
      right.className = classNameRightHandle;
      right.style.position = "absolute";
      // right.style.backgroundColor = "#9c00ff";
      right.style.right = "0px";
      right.style.top = "0px";
      right.style.width = "20px";
      right.style.maxWidth = "20%";
      right.style.height = "100%";
      right.style.cursor = "e-resize";
      this.bar.appendChild(right);

    }
  }

  private registerMouseHandler(renderInfo: RenderInfo) {
    const jBody = jQuery("body");
    let startX: number;

    let initialStartDate: string = null;
    let initialDueDate: string = null;

    const applyDateValues = (start: Moment, due: Moment) => {
      const wp = renderInfo.workPackage;
      wp.startDate = start ? start.format("YYYY-MM-DD") as any : null;
      wp.dueDate = due ? due.format("YYYY-MM-DD") as any : null;
      this.wpCacheService.updateWorkPackage(wp as any);
    };

    const mouseMoveFn = (ev: JQueryEventObject) => {
      const mev: MouseEvent = ev as any;
      const distance = Math.floor((mev.clientX - startX) / renderInfo.viewParams.pixelPerDay);
      const days = distance < 0 ? distance + 1 : distance;

      const start = initialStartDate ? moment(initialStartDate).add(days, "days") : null;
      const due = initialDueDate ? moment(initialDueDate).add(days, "days") : null;

      applyDateValues(start, due);
    };

    const keyPressFn = (ev: JQueryEventObject) => {
      const kev: KeyboardEvent = ev as any;

      // ESC
      if (kev.keyCode === 27) {
        deregister(true);
      }
    };

    const deregister = (cancelled: boolean) => {
      jBody.off("mousemove", mouseMoveFn);
      jBody.off("keyup", keyPressFn);

      if (cancelled) {
        applyDateValues(moment(initialStartDate), moment(initialDueDate));
      }

      initialStartDate = null;
      initialDueDate = null;
    };

    this.bar.onmousedown = (ev: MouseEvent) => {
      ev.preventDefault();

      const className = (ev.target as HTMLElement).className;
      startX = ev.clientX;
      if (className !== classNameRightHandle) {
        initialStartDate = renderInfo.workPackage.startDate as any;
      }
      if (className !== classNameLeftHandle) {
        initialDueDate = renderInfo.workPackage.dueDate as any;
      }
      jBody.on("mousemove", mouseMoveFn);
      jBody.on("keyup", keyPressFn);
    };

    jBody.on("mouseup", () => {
      deregister(false);
    });
  }

  private updateView(renderInfo: RenderInfo) {
    // console.log("updateView() wpId=" + this.workPackageId);

    // display bar
    this.lazyInit(renderInfo);
    const viewParams = renderInfo.viewParams;
    const wp = renderInfo.workPackage;

    // update global elements
    // this.updateGlobalElements(renderInfo);

    // abort if no start or due date
    if (!wp.startDate || !wp.dueDate) {
      return;
    }

    // general settings - bar
    this.bar.style.position = "relative";
    this.bar.style.height = "1em";
    this.bar.style.backgroundColor = "#8CD1E8";
    this.bar.style.borderRadius = "2px";
    this.bar.style.cssFloat = "left";
    this.bar.style.zIndex = "50";
    this.bar.style.marginLeft = renderInfo.viewParams.scrollOffsetInPx + "px";
    this.bar.style.cursor = "ew-resize";
    // this.bar.style.cursor = "move";

    const start = moment(wp.startDate as any);
    const due = moment(wp.dueDate as any);

    // offset left
    const offsetStart = start.diff(viewParams.dateDisplayStart, "days");
    this.bar.style.left = calculatePositionValueForDayCount(viewParams, offsetStart);

    // duration
    const duration = due.diff(start, "days") + 1;
    this.bar.style.width = calculatePositionValueForDayCount(viewParams, duration);
  }

}
