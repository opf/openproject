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
import {WorkPackageResourceInterface} from "../../api/api-v3/hal-resources/work-package-resource.service";
import IScope = angular.IScope;
import Moment = moment.Moment;

const keyCodeESC = 27;

const classNameBar = "bar";
export const classNameLeftHandle = "leftHandle";
export const classNameRightHandle = "rightHandle";


function createPlaceholderForEmptyCell() {
  const placeholder = document.createElement("div");
  placeholder.style.pointerEvents = "none";
  placeholder.style.backgroundColor = "#DDDDDD";
  placeholder.style.position = "absolute";
  placeholder.style.height = "1em";
  placeholder.style.width = "30px";
  return placeholder;
}

export function registerWorkPackageMouseHandler(this: void,
                                                getRenderInfo: () => RenderInfo,
                                                workPackageTimeline: WorkPackageTimelineTableController,
                                                wpCacheService: WorkPackageCacheService,
                                                cell: HTMLElement,
                                                bar: HTMLDivElement,
                                                renderer: TimelineCellRenderer,
                                                renderInfo: RenderInfo) {

  let startX: number = null; // also flag to signal active drag'n'drop
  let dateStates:any;
  const jBody = jQuery("body");
  const placeholderForEmptyCell = createPlaceholderForEmptyCell();

  // handle mouse move on cell
  cell.onmousemove = handleMouseMoveOnEmptyCell;

  bar.onmousedown = (ev: MouseEvent) => {
    workPackageMouseDownFn(ev);
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

  function createMouseMoveFn(direction: "left" | "right" | "both") {
    return (ev: JQueryEventObject) => {
      const mev: MouseEvent = ev as any;
      const distance = Math.floor((mev.clientX - startX) / renderInfo.viewParams.pixelPerDay);
      const days = distance < 0 ? distance + 1 : distance;

      dateStates = renderer.onDaysMoved(renderInfo.workPackage, days, direction);
      applyDateValues(dateStates);
    }
  }

  function keyPressFn(ev: JQueryEventObject) {
    const kev: KeyboardEvent = ev as any;
    if (kev.keyCode === keyCodeESC) {
      deactivate(true);
    }
  }

  function workPackageMouseDownFn(ev: MouseEvent) {
    ev.preventDefault();

    workPackageTimeline.disableViewParamsCalculation = true;
    startX = ev.clientX;

    // Determine what attributes of the work package should be changed
    const direction = renderer.onMouseDown(ev, renderInfo, bar);

    jBody.on("mousemove", createMouseMoveFn(direction));
    jBody.on("keyup", keyPressFn);
  }

  function handleMouseMoveOnEmptyCell(ev: MouseEvent) {
    const renderInfo = getRenderInfo();
    const wp = renderInfo.workPackage;
    const start = moment(wp.startDate as any);
    const due = moment(wp.dueDate as any);
    const noStartDueValues = _.isNaN(start.valueOf()) && _.isNaN(due.valueOf());

    if (!noStartDueValues) {
      return;
    }

    // placeholder logic
    const days = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);
    // const dayUnderCursor = renderInfo.viewParams.dateDisplayStart.clone().add(days, "days");
    placeholderForEmptyCell.style.left = (days * renderInfo.viewParams.pixelPerDay) + "px";
    cell.appendChild(placeholderForEmptyCell);
    cell.onmouseleave = () => {
      placeholderForEmptyCell.remove();
    };

    // create logic
    cell.onmousedown = (ev) => {
      console.log("create - mouse down");
      placeholderForEmptyCell.remove();
      ev.preventDefault();

      bar.style.pointerEvents = "none";

      const days = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);
      const clickStart = renderInfo.viewParams.dateDisplayStart.clone().add(days, "days");
      renderInfo.workPackage.startDate = clickStart.format("YYYY-MM-DD");
      renderInfo.workPackage.dueDate = clickStart.format("YYYY-MM-DD");
      renderer.update(cell, bar, renderInfo);

      function cancel(resetStartDueValues: boolean) {
        console.log("create - cancel()");
        jBody.off(".create");

        if (resetStartDueValues) {
          renderInfo.workPackage.startDate = null;
          renderInfo.workPackage.dueDate = null;
        }
        bar.style.pointerEvents = "auto";
        renderer.update(cell, bar, renderInfo);

        cell.onmousemove = handleMouseMoveOnEmptyCell;
      }

      cell.onmousemove = (ev) => {
        console.log("create - mouse move");
        const days = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);
        const currentEnd = renderInfo.viewParams.dateDisplayStart.clone().add(days, "days");
        renderInfo.workPackage.dueDate = currentEnd.format("YYYY-MM-DD");
        renderer.update(cell, bar, renderInfo);
      };

      cell.onmouseleave = () => {
        cancel(true);
      };

      cell.onmouseup = () => {
        cancel(false);
        saveWorkPackage(renderInfo.workPackage);
      };

      jBody.on("keyup.create", (ev) => {
        const kev: KeyboardEvent = ev as any;
        if (kev.keyCode === keyCodeESC) {
          cancel(true);
        }
      });
    };
  }

  function deactivate(cancelled: boolean) {
    workPackageTimeline.disableViewParamsCalculation = false;

    if (startX == null) {
      return;
    }

    jBody.off("mousemove");
    jBody.off("keyup");
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
    saveWorkPackage(renderInfo.workPackage);
  }

  function saveWorkPackage(workPackage: WorkPackageResourceInterface) {
    console.log("saveWorkPackage()");

    wpCacheService.saveIfChanged(workPackage)
      .catch(() => {
        // Reset the changes on error
        renderer.onCancel(workPackage);
      })
      .finally(() => {
        workPackageTimeline.refreshView();
      });
  }
}

