// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import * as moment from 'moment';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';

import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { take } from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageCellLabels } from './wp-timeline-cell';
import { TimelineCellRenderer } from './timeline-cell-renderer';
import { RenderInfo } from '../wp-timeline';
import { WorkPackageTimelineTableController } from '../container/wp-timeline-container.directive';
import Moment = moment.Moment;

export const classNameBar = 'bar';
export const classNameLeftHandle = 'leftHandle';
export const classNameRightHandle = 'rightHandle';
export const classNameBarLabel = 'bar-label';

export type MouseDirection = 'left'|'right'|'both'|'create'|'dragright';

export function registerWorkPackageMouseHandler(this:void,
  injector:Injector,
  getRenderInfo:() => RenderInfo,
  workPackageTimeline:WorkPackageTimelineTableController,
  halEditing:HalResourceEditingService,
  halEvents:HalEventsService,
  notificationService:WorkPackageNotificationService,
  loadingIndicator:LoadingIndicatorService,
  cell:HTMLElement,
  bar:HTMLDivElement,
  labels:WorkPackageCellLabels,
  renderer:TimelineCellRenderer,
  renderInfo:RenderInfo) {
  const querySpace:IsolatedQuerySpace = injector.get(IsolatedQuerySpace);

  let mouseDownStartDay:number|null = null; // also flag to signal active drag'n'drop
  renderInfo.change = halEditing.changeFor(renderInfo.workPackage);

  let placeholderForEmptyCell:HTMLElement;
  const jBody = jQuery('body');

  // handles change to existing work packages
  bar.onmousedown = (ev:MouseEvent) => {
    if (ev.which === 1) {
      // Left click only
      workPackageMouseDownFn(bar, ev);
    }
  };

  // handles initial creation of start/due values
  cell.onmousemove = handleMouseMoveOnEmptyCell;

  function applyRendererMoveChanges(dayUnderCursor:Moment, days:number, direction:MouseDirection) {
    const moved = renderer.onDaysMoved(renderInfo.change, dayUnderCursor, days, direction);
    renderer.assignDateValues(renderInfo.change, labels, moved);
    renderer.update(bar, labels, renderInfo);
  }

  function getCursorOffsetInDaysFromLeft(renderInfo:RenderInfo, ev:MouseEvent) {
    const leftOffset = workPackageTimeline.getAbsoluteLeftCoordinates();
    const cursorOffsetLeftInPx = ev.clientX - leftOffset;
    const cursorOffsetLeftInDays = Math.floor(cursorOffsetLeftInPx / renderInfo.viewParams.pixelPerDay);
    return cursorOffsetLeftInDays;
  }

  function workPackageMouseDownFn(bar:HTMLDivElement, ev:MouseEvent) {
    ev.preventDefault();

    // add/remove css class while drag'n'drop is active
    const classNameActiveDrag = 'active-drag';
    bar.classList.add(classNameActiveDrag);
    jBody.on('mouseup.timelinecell', () => bar.classList.remove(classNameActiveDrag));

    workPackageTimeline.disableViewParamsCalculation = true;
    mouseDownStartDay = getCursorOffsetInDaysFromLeft(renderInfo, ev);

    // If this wp is a parent element, changing it is not allowed
    // if it is not on 'Manual scheduling' mode
    // But adding a relation to it is.
    if (!renderInfo.workPackage.isLeaf && !renderInfo.viewParams.activeSelectionMode && !renderInfo.workPackage.scheduleManually) {
      return;
    }

    // Determine what attributes of the work package should be changed
    const direction = renderer.onMouseDown(ev, null, renderInfo, labels);

    jBody.on('mousemove.timelinecell', createMouseMoveFn(direction));
    jBody.on('keyup.timelinecell', keyPressFn);
    jBody.on('mouseup.timelinecell', () => deactivate(false));
  }

  function createMouseMoveFn(direction:MouseDirection) {
    return (ev:JQuery.MouseMoveEvent) => {
      const days = getCursorOffsetInDaysFromLeft(renderInfo, ev.originalEvent!) - mouseDownStartDay!;
      const offsetDayCurrent = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);
      const dayUnderCursor = renderInfo.viewParams.dateDisplayStart.clone().add(offsetDayCurrent, 'days');

      applyRendererMoveChanges(dayUnderCursor, days, direction);
    };
  }

  function keyPressFn(ev:JQuery.TriggeredEvent) {
    const kev:KeyboardEvent = ev as any;
    if (kev.keyCode === KeyCodes.ESCAPE) {
      deactivate(true);
    }
  }

  function handleMouseMoveOnEmptyCell(ev:MouseEvent) {
    const wp = renderInfo.workPackage;

    if (!renderer.isEmpty(wp)) {
      return;
    }

    // placeholder logic
    placeholderForEmptyCell && placeholderForEmptyCell.remove();
    placeholderForEmptyCell = renderer.displayPlaceholderUnderCursor(ev, renderInfo);

    const isEditable =
      (wp.isLeaf || wp.scheduleManually)
      && renderer.canMoveDates(wp)
      && !renderer.isCursorOnInvalidDay(ev, renderInfo);

    if (!isEditable) {
      cell.style.cursor = 'not-allowed';
      return;
    }

    // display placeholder only if the timeline is editable
    cell.style.cursor = '';
    cell.appendChild(placeholderForEmptyCell);

    // abort if mouse leaves cell
    cell.onmouseleave = () => {
      placeholderForEmptyCell.remove();
    };

    // create logic
    cell.onmousedown = (ev) => {
      placeholderForEmptyCell.remove();

      if (renderer.isCursorOnInvalidDay(ev, renderInfo)) {
        deactivate(true);
        ev.preventDefault();
        return;
      }

      bar.style.pointerEvents = 'none';
      ev.preventDefault();

      const [clickStart, offsetDayStart] = renderer.cursorDateAndDayOffset(ev, renderInfo);
      const dateForCreate = clickStart.format('YYYY-MM-DD');
      const mouseDownType = renderer.onMouseDown(ev, dateForCreate, renderInfo, labels);
      renderer.update(bar, labels, renderInfo);
      if (mouseDownType === 'create') {
        deactivate(false);
        ev.preventDefault();
        return;
      }

      jBody.on('mousemove.emptytimelinecell', mouseMoveOnEmptyCellFn(offsetDayStart, mouseDownType));
      jBody.on('mouseup.emptytimelinecell', () => deactivate(false));

      cell.onmouseup = (ev) => {
        deactivate(renderer.isCursorOnInvalidDay(ev, renderInfo));
      };

      jBody.on('keyup.timelinecell', keyPressFn);
    };
  }

  function mouseMoveOnEmptyCellFn(offsetDayStart:number, mouseDownType:MouseDirection) {
    return (ev:JQuery.MouseMoveEvent) => {
      placeholderForEmptyCell.remove();
      const relativePosition = Math.abs(cell.getBoundingClientRect().x - ev.clientX);
      const offsetDayCurrent = Math.floor(relativePosition / renderInfo.viewParams.pixelPerDay);
      const dayUnderCursor = renderInfo.viewParams.dateDisplayStart.clone().add(offsetDayCurrent, 'days');
      const widthInDays = offsetDayCurrent - offsetDayStart;

      applyRendererMoveChanges(dayUnderCursor, widthInDays, mouseDownType);
    };
  }

  function deactivate(cancelled:boolean) {
    workPackageTimeline.disableViewParamsCalculation = false;

    cell.onmousemove = handleMouseMoveOnEmptyCell;
    cell.onmousedown = _.noop;
    cell.onmouseleave = _.noop;
    cell.onmouseup = _.noop;

    bar.style.pointerEvents = 'auto';

    jBody.off('.timelinecell');
    jBody.off('.emptytimelinecell');
    workPackageTimeline.resetCursor();
    mouseDownStartDay = null;

    // const renderInfo = getRenderInfo();
    if (cancelled || renderInfo.change.isEmpty()) {
      cancelChange();
    } else {
      const stopAndRefresh = () => {
        renderInfo.change.clear();
        renderer.onMouseDownEnd(labels, renderInfo.change);
      };

      // Persist the changes
      saveWorkPackage(renderInfo.change)
        .then(stopAndRefresh)
        .catch((error) => {
          notificationService.handleRawError(error, renderInfo.workPackage);
          cancelChange();
        });
    }
  }

  function cancelChange() {
    renderInfo.change.clear();
    renderer.update(bar, labels, renderInfo);
    renderer.onMouseDownEnd(labels, renderInfo.change);
    workPackageTimeline.refreshView();
  }

  function saveWorkPackage(change:WorkPackageChangeset) {
    const apiv3Service:ApiV3Service = injector.get(ApiV3Service);
    const querySpace:IsolatedQuerySpace = injector.get(IsolatedQuerySpace);

    // Remember the time before saving the work package to know which work packages to update
    const updatedAt = moment().toISOString();

    return loadingIndicator.table.promise = halEditing
      .save<WorkPackageResource, WorkPackageChangeset>(change)
      .then((result) => {
        notificationService.showSave(result.resource);
        const ids = _.map(querySpace.tableRendered.value, (row) => row.workPackageId);
        return apiv3Service
          .work_packages
          .filterUpdatedSince(ids, updatedAt)
          .get()
          .toPromise()
          .then(() => {
            halEvents.push(result.resource, { eventType: 'updated' });
            return querySpace.timelineRendered.pipe(take(1)).toPromise();
          });
      });
  }
}
