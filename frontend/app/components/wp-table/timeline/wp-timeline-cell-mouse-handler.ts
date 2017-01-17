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
import {WorkPackageTimelineTableController} from "./wp-timeline-container.directive";
import {TimelineCellRenderer} from "./cell-renderer/timeline-cell-renderer";
import IScope = angular.IScope;
import Moment = moment.Moment;

const classNameBar = "bar";
const classNameLeftHandle = "leftHandle";
const classNameRightHandle = "rightHandle";


export function registerWorkPackageMouseHandler(this: void,
                                                workPackageTimeline: WorkPackageTimelineTableController,
                                                wpCacheService: WorkPackageCacheService,
                                                bar: HTMLElement,
                                                renderer: TimelineCellRenderer,
                                                renderInfo: RenderInfo) {

  let startX: number = null; // also flag to signal active drag'n'drop
  let dateStates:any;
  let jBody = jQuery("body");

  bar.onmousedown = (ev: MouseEvent) => {
    mouseDownFn(ev);
  };

  jBody.on("mouseup", () => {
      deactivate(false);
    }
  );

  function applyDateValues(dates:{[name:string]: Moment}) {
    const wp = renderInfo.workPackage;

    // Let the renderer decide which fields we change
    renderer.assignDateValues(wp, dates);

    // Update the work package to refresh dates columns
    wpCacheService.updateWorkPackage(wp);
  }

  function mouseMoveFn(ev: JQueryEventObject) {

    const mev: MouseEvent = ev as any;
    const distance = Math.floor((mev.clientX - startX) / renderInfo.viewParams.pixelPerDay);
    const days = distance < 0 ? distance + 1 : distance;

    dateStates = renderer.onDaysMoved(renderInfo.workPackage, days);

    applyDateValues(dateStates);
  }

  function keyPressFn(ev: JQueryEventObject) {
    const kev: KeyboardEvent = ev as any;
    if (kev.keyCode === 27) { // ESC
      deactivate(true);
    }
  }

  function mouseDownFn(ev: MouseEvent) {
    ev.preventDefault();

    workPackageTimeline.disableViewParamsCalculation = true;
    startX = ev.clientX;

    // Determine what attributes of the work package should be changed
    renderer.onMouseDown(ev, renderInfo, bar);

    jBody.on("mousemove", mouseMoveFn);
    jBody.on("keyup", keyPressFn);
  }

  function deactivate(cancelled: boolean) {
    workPackageTimeline.disableViewParamsCalculation = false;

    if (startX == null) {
      return;
    }

    jBody.off("mousemove", mouseMoveFn);
    jBody.off("keyup", keyPressFn);
    jQuery(".hascontextmenu").css("cursor", "context-menu");
    jQuery("." + timelineElementCssClass).css("cursor", '');
    jQuery("." + classNameLeftHandle).css("cursor", "w-resize");
    jQuery("." + classNameBar).css("cursor", "ew-resize");
    jQuery("." + classNameRightHandle).css("cursor", "e-resize");
    startX = null;
    dateStates = {};

    renderer.onMouseDownEnd();
    if (cancelled) {
      renderer.onCancel(renderInfo.workPackage);
      return workPackageTimeline.refreshView();
    }

    // Persist the changes
    wpCacheService.saveIfChanged(renderInfo.workPackage)
      .catch(() => {
        // Reset the changes on error
        renderer.onCancel(renderInfo.workPackage);
      })
      .finally(() => {
        workPackageTimeline.refreshView();
      });
  }
}

