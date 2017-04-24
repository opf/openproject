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
import {keyCodes} from "../../common/keyCodes.enum";
import IScope = angular.IScope;
import * as moment from 'moment';
import Moment = moment.Moment;

const classNameBar = "bar";
export const classNameLeftHandle = "leftHandle";
export const classNameRightHandle = "rightHandle";


function getCursorOffsetInDaysFromLeft(renderInfo: RenderInfo, ev: MouseEvent) {
  const header = renderInfo.viewParams.timelineHeader;
  const headerLeft = header.getAbsoluteLeftCoordinates();
  const cursorOffsetLeftInPx = ev.clientX - headerLeft;
  const cursorOffsetLeftInDays = Math.floor(cursorOffsetLeftInPx / renderInfo.viewParams.pixelPerDay);
  return cursorOffsetLeftInDays;
}

export function registerWorkPackageMouseHandler(this: void,
                                                getRenderInfo: () => RenderInfo,
                                                workPackageTimeline: WorkPackageTimelineTableController,
                                                wpCacheService: WorkPackageCacheService,
                                                cell: HTMLElement,
                                                bar: HTMLDivElement,
                                                renderer: TimelineCellRenderer,
                                                renderInfo: RenderInfo) {

  let mouseDownStartDay: number|null = null;// also flag to signal active drag'n'drop

  let dateStates:any;
  let placeholderForEmptyCell: HTMLElement;
  const jBody = jQuery("body");

  // handles change to existing work packages
  bar.onmousedown = (ev: MouseEvent) => {
    workPackageMouseDownFn(ev);
  };

  // handles initial creation of start/due values
  cell.onmousemove = handleMouseMoveOnEmptyCell;

  function applyDateValues(dates:{[name:string]: Moment}) {
    const wp = renderInfo.workPackage;

    // Let the renderer decide which fields we change
    renderer.assignDateValues(wp, dates);

    // Update the work package to refresh dates columns
    wpCacheService.updateWorkPackage(wp);
  }

  function workPackageMouseDownFn(ev: MouseEvent) {
    ev.preventDefault();

    workPackageTimeline.disableViewParamsCalculation = true;
    mouseDownStartDay = getCursorOffsetInDaysFromLeft(renderInfo, ev);

    // if this wp is a parent element, changing it is not allowed
    if (!renderInfo.workPackage.isLeaf) {
      return;
    }

      // Determine what attributes of the work package should be changed
    const direction = renderer.onMouseDown(ev, null, renderInfo, bar);

    jBody.on("mousemove", createMouseMoveFn(direction));
    jBody.on("keyup", keyPressFn);
    jBody.on("mouseup", () => deactivate(false));
  }

  function createMouseMoveFn(direction: "left" | "right" | "both" | "create" | "dragright") {
    return (ev: JQueryEventObject) => {
      const mev: MouseEvent = ev as any;

      const days = getCursorOffsetInDaysFromLeft(renderInfo, mev) - mouseDownStartDay!;
      const offsetDayCurrent = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);
      const dayUnderCursor = renderInfo.viewParams.dateDisplayStart.clone().add(offsetDayCurrent, "days");

      dateStates = renderer.onDaysMoved(renderInfo.workPackage, dayUnderCursor, days, direction);
      applyDateValues(dateStates);
    }
  }

  function keyPressFn(ev: JQueryEventObject) {
    const kev: KeyboardEvent = ev as any;
    if (kev.keyCode === keyCodes.ESCAPE) {
      deactivate(true);
    }
  }

  function handleMouseMoveOnEmptyCell(ev: MouseEvent) {
    // const renderInfo = getRenderInfo();
    const wp = renderInfo.workPackage;


    if (!renderer.isEmpty(wp)) {
      return;
    }

    // placeholder logic
    placeholderForEmptyCell && placeholderForEmptyCell.remove();
    placeholderForEmptyCell = renderer.displayPlaceholderUnderCursor(ev, renderInfo);
    cell.appendChild(placeholderForEmptyCell);

    // abort if mouse leaves cell
    cell.onmouseleave = () => {
      placeholderForEmptyCell.remove();
    };

    // create logic
    cell.onmousedown = (ev) => {
      placeholderForEmptyCell.remove();
      bar.style.pointerEvents = "none";
      ev.preventDefault();

      const offsetDayStart = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);
      const clickStart = renderInfo.viewParams.dateDisplayStart.clone().add(offsetDayStart, "days");
      const dateForCreate = clickStart.format("YYYY-MM-DD");
      const mouseDownType = renderer.onMouseDown(ev, dateForCreate, renderInfo, bar);
      renderer.update(cell, bar, renderInfo);

      if (mouseDownType === "create") {
        deactivate(false);
        ev.preventDefault();
        return;
      }

      cell.onmousemove = (ev) => {
        const offsetDayCurrent = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);
        const dayUnderCursor = renderInfo.viewParams.dateDisplayStart.clone().add(offsetDayCurrent, "days");
        const widthInDays = offsetDayCurrent - offsetDayStart;
        const moved = renderer.onDaysMoved(wp, dayUnderCursor, widthInDays, mouseDownType);
        renderer.assignDateValues(wp, moved);
        wpCacheService.updateWorkPackage(wp);

      };

      cell.onmouseleave = () => {
        deactivate(true);
      };

      cell.onmouseup = () => {
        deactivate(false);
      };

      jBody.on("keyup", keyPressFn);
    };
  }

  function deactivate(cancelled: boolean) {
    workPackageTimeline.disableViewParamsCalculation = false;

    cell.onmousemove = handleMouseMoveOnEmptyCell;
    cell.onmousedown = _.noop;
    cell.onmouseleave = _.noop;
    cell.onmouseup = _.noop;

    bar.style.pointerEvents = "auto";
    jBody.off("mouseup");
    jBody.off("mousemove");
    jBody.off("keyup");
    jQuery(".hascontextmenu").css("cursor", "context-menu");
    jQuery("." + timelineElementCssClass).css("cursor", '');
    jQuery("." + classNameLeftHandle).css("cursor", "w-resize");
    jQuery("." + classNameBar).css("cursor", "ew-resize");
    jQuery("." + classNameRightHandle).css("cursor", "e-resize");
    mouseDownStartDay = null;
    dateStates = {};

    renderer.onMouseDownEnd();

    // const renderInfo = getRenderInfo();
    const wp = renderInfo.workPackage;
    if (cancelled) {
      // cancelled
      renderer.onCancel(wp);
      wpCacheService.updateWorkPackage(wp);
      workPackageTimeline.refreshView();
    } else {
      // Persist the changes
      saveWorkPackage(wp);
    }
  }

  function saveWorkPackage(workPackage: WorkPackageResourceInterface) {
    wpCacheService.saveIfChanged(workPackage)
      .catch(() => {
        if (!workPackage.isNew) {
          // Reset the changes on error
          renderer.onCancel(workPackage);
        }

        workPackageTimeline.refreshView();
      });
  }
}

