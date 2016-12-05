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
import {timelineElementCssClass, RenderInfo} from "./wp-timeline";
import {WorkPackageCacheService} from "../../work-packages/work-package-cache.service";
import IScope = angular.IScope;
import WorkPackage = op.WorkPackage;
import Observable = Rx.Observable;
import IDisposable = Rx.IDisposable;
import Moment = moment.Moment;

const classNameBar = "bar";
const classNameLeftHandle = "leftHandle";
const classNameRightHandle = "rightHandle";


export function registerWorkPackageMouseHandler(this: void,
                                                wpCacheService: WorkPackageCacheService,
                                                bar: HTMLElement,
                                                renderInfo: RenderInfo) {

  let startX: number = null; // also flag to signal active drag'n'drop
  let initialStartDate: string = null;
  let initialDueDate: string = null;
  let jBody = jQuery("body");

  bar.onmousedown = (ev: MouseEvent) => {
    mouseDownFn(ev);
  };

  jBody.on("mouseup", () => {
      deactivate(false);
    }
  );

  function applyDateValues(start: Moment, due: Moment) {
    const wp = renderInfo.workPackage;
    wp.startDate = start ? start.format("YYYY-MM-DD") as any : wp.startDate;
    wp.dueDate = due ? due.format("YYYY-MM-DD") as any : wp.dueDate;
    wpCacheService.updateWorkPackage(wp as any);
  }

  function mouseMoveFn(ev: JQueryEventObject) {
    const mev: MouseEvent = ev as any;
    const distance = Math.floor((mev.clientX - startX) / renderInfo.viewParams.pixelPerDay);
    const days = distance < 0 ? distance + 1 : distance;
    const start = initialStartDate ? moment(initialStartDate).add(days, "days") : null;
    const due = initialDueDate ? moment(initialDueDate).add(days, "days") : null;
    applyDateValues(start, due);
  }

  function keyPressFn(ev: JQueryEventObject) {
    const kev: KeyboardEvent = ev as any;
    if (kev.keyCode === 27) { // ESC
      deactivate(true);
    }
  }

  function mouseDownFn(ev: MouseEvent) {
    ev.preventDefault();

    // Set cursor
    if (jQuery(ev.target).hasClass(classNameLeftHandle)) {
      jQuery(".hascontextmenu").css("cursor", "w-resize");
      jQuery("." + timelineElementCssClass).css("cursor", "w-resize");
    } else if (jQuery(ev.target).hasClass(classNameRightHandle)) {
      jQuery(".hascontextmenu").css("cursor", "e-resize");
      jQuery("." + timelineElementCssClass).css("cursor", "e-resize");
    } else {
      jQuery(".hascontextmenu").css("cursor", "ew-resize");
      jQuery("." + timelineElementCssClass).css("cursor", "ew-resize");
    }

    // Determine what of start/due should be changed
    startX = ev.clientX;
    if (!jQuery(ev.target).hasClass(classNameRightHandle)) {
      initialStartDate = renderInfo.workPackage.startDate as any;
    }
    if (!jQuery(ev.target).hasClass(classNameLeftHandle)) {
      initialDueDate = renderInfo.workPackage.dueDate as any;
    }

    jBody.on("mousemove", mouseMoveFn);
    jBody.on("keyup", keyPressFn);
  }

  function deactivate(cancelled: boolean) {
    if (startX == null) {
      return;
    }

    if (cancelled) {
      applyDateValues(
        initialStartDate ? moment(initialStartDate) : null,
        initialDueDate ? moment(initialDueDate) : null);
    }

    jBody.off("mousemove", mouseMoveFn);
    jBody.off("keyup", keyPressFn);
    jQuery(".hascontextmenu").css("cursor", "context-menu");
    jQuery("." + timelineElementCssClass).css("cursor", "auto");
    jQuery("." + classNameLeftHandle).css("cursor", "w-resize");
    jQuery("." + classNameBar).css("cursor", "ew-resize");
    jQuery("." + classNameRightHandle).css("cursor", "e-resize");
    startX = null;
    initialStartDate = null;
    initialDueDate = null;
  }

}

