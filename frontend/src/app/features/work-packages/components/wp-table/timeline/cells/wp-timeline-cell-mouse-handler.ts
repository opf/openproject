//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
import moment, { Moment } from 'moment';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';

import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { take } from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageCellLabels } from './wp-timeline-cell-labels';
import {
  MouseDirection,
  TimelineCellRenderer,
} from './timeline-cell-renderer';
import { RenderInfo } from '../wp-timeline';
import { WorkPackageTimelineTableController } from '../container/wp-timeline-container.directive';
import { target } from 'core-app/shared/helpers/event-helpers';

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
  renderInfo:RenderInfo):void {
  let mouseDownStartDay:number|null = null; // also flag to signal active drag'n'drop
  renderInfo.change = halEditing.changeFor(renderInfo.workPackage);

  let placeholderForEmptyCell:HTMLElement;
  const bodyTarget = target(document.body);

  // handles change to existing work packages
  bar.onmousedown = (ev:MouseEvent) => {
    if (!ev.button || ev.button === 0) {
      // Left click only
      workPackageMouseDownFn(ev);
    }
  };

  // handles initial creation of start/due values
  cell.onmousemove = handleMouseMoveOnEmptyCell;

  function applyRendererMoveChanges(dayUnderCursor:Moment, days:number, direction:MouseDirection) {
    const moved = renderer.onDaysMoved(renderInfo.change, dayUnderCursor, days, direction);
    renderer.assignDateValues(renderInfo.change, labels, moved);
    renderer.update(bar, labels, renderInfo);
  }

  function getCursorOffsetInDaysFromLeft(ev:MouseEvent):number {
    const leftOffset = workPackageTimeline.getAbsoluteLeftCoordinates();
    const cursorOffsetLeftInPx = ev.clientX - leftOffset;
    return Math.floor(cursorOffsetLeftInPx / renderInfo.viewParams.pixelPerDay);
  }

  function workPackageMouseDownFn(ev:MouseEvent) {
    ev.preventDefault();

    // add/remove css class while drag'n'drop is active
    const classNameActiveDrag = 'active-drag';
    bar.classList.add(classNameActiveDrag);
    bodyTarget.on('mouseup.timelinecell', () => bar.classList.remove(classNameActiveDrag));

    workPackageTimeline.disableViewParamsCalculation = true;
    mouseDownStartDay = getCursorOffsetInDaysFromLeft(ev);

    // If this wp is a parent element, changing it is not allowed
    // if it is not on 'Manual scheduling' mode
    // But adding a relation to it is.
    if (!renderInfo.workPackage.isLeaf && !renderInfo.viewParams.activeSelectionMode && !renderInfo.workPackage.scheduleManually) {
      return;
    }

    // Determine what attributes of the work package should be changed
    const direction = renderer.onMouseDown(ev, null, renderInfo, labels);

    bodyTarget.on('mousemove.timelinecell', createMouseMoveFn(direction));
    bodyTarget.on('keyup.timelinecell', keyPressFn);
    bodyTarget.on('mouseup.timelinecell', () => deactivate(direction, false));
  }

  function createMouseMoveFn(direction:MouseDirection) {
    return (ev:MouseEvent) => {
      const days = getCursorOffsetInDaysFromLeft(ev) - (mouseDownStartDay!);
      const offsetDayCurrent = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);
      const dayUnderCursor = renderInfo.viewParams.dateDisplayStart.clone().add(offsetDayCurrent, 'days');

      applyRendererMoveChanges(dayUnderCursor, days, direction);
    };
  }

  function keyPressFn(kev:KeyboardEvent) {
    if (kev.key === 'Escape') {
      deactivate(null, true);
    }
  }

  function handleMouseMoveOnEmptyCell(ev:MouseEvent) {
    const wp = renderInfo.workPackage;

    if (!renderer.isEmpty(wp)) {
      return;
    }

    // placeholder logic
    placeholderForEmptyCell?.remove();
    placeholderForEmptyCell = renderer.displayPlaceholderUnderCursor(ev, renderInfo);

    const isEditable = (wp.isLeaf || wp.scheduleManually)
      && renderer.canMoveDates(wp)
      && !renderer.cursorOrDatesAreNonWorking(ev, renderInfo);

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
    cell.onmousedown = (evt) => {
      placeholderForEmptyCell.remove();

      evt.preventDefault();

      if (renderer.cursorOrDatesAreNonWorking(evt, renderInfo)) {
        return;
      }

      bar.style.pointerEvents = 'none';

      const [clickStart, offsetDayStart] = renderer.cursorDateAndDayOffset(evt, renderInfo);
      const dateForCreate = clickStart.format('YYYY-MM-DD');
      const direction = renderer.onMouseDown(evt, dateForCreate, renderInfo, labels);
      renderer.update(bar, labels, renderInfo);

      if (direction === 'create') {
        deactivate(direction, false);
        return;
      }

      bodyTarget.on('mousemove.emptytimelinecell', mouseMoveOnEmptyCellFn(offsetDayStart, direction));
      bodyTarget.on('mouseup.emptytimelinecell', () => deactivate(direction, false));

      cell.onmouseup = () => {
        deactivate(direction, false);
      };

      bodyTarget.on('keyup.timelinecell', keyPressFn);
    };
  }

  function mouseMoveOnEmptyCellFn(offsetDayStart:number, mouseDownType:MouseDirection) {
    return (ev:MouseEvent) => {
      placeholderForEmptyCell.remove();
      const relativePosition = Math.abs(cell.getBoundingClientRect().x - ev.clientX);
      const offsetDayCurrent = Math.floor(relativePosition / renderInfo.viewParams.pixelPerDay);
      const dayUnderCursor = renderInfo.viewParams.dateDisplayStart.clone().add(offsetDayCurrent, 'days');
      const widthInDays = offsetDayCurrent - offsetDayStart;

      applyRendererMoveChanges(dayUnderCursor, widthInDays, mouseDownType);
    };
  }

  function deactivate(direction:MouseDirection|null, cancelled:boolean) {
    const change = renderInfo.change;
    workPackageTimeline.disableViewParamsCalculation = false;

    cell.onmousemove = handleMouseMoveOnEmptyCell;
    cell.onmousedown = () => undefined;
    cell.onmouseleave = () => undefined;
    cell.onmouseup = () => undefined;

    bar.style.pointerEvents = 'auto';

    bodyTarget.off('.timelinecell');
    bodyTarget.off('.emptytimelinecell');
    workPackageTimeline.resetCursor();
    mouseDownStartDay = null;

    // Cancel changes if the startDate or dueDate are not allowed
    const { startDate, dueDate } = change.projectedResource;
    const invalidDates = renderer.cursorOrDatesAreNonWorking([moment(startDate), moment(dueDate)], renderInfo, direction);

    if (cancelled || change.isEmpty() || invalidDates) {
      cancelChange();
      return;
    }

    // Remove due date from sending if we moved the work package as is
    // and duration was set
    const duration = change.pristineResource.duration as string|null;
    if (direction === 'both' && duration) {
      change.clearValue('dueDate');
      change.setValue('duration', duration);
    }

    // Persist the changes
    saveWorkPackage(renderInfo.change)
      .then(() => {
        renderInfo.change.clear();
        renderer.onMouseDownEnd(labels, renderInfo.change);
      })
      .catch((error) => {
        notificationService.handleRawError(error, renderInfo.workPackage);
        cancelChange();
      });
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

    return (loadingIndicator.table.promise = halEditing
      .save<WorkPackageResource, WorkPackageChangeset>(change)
      .then((result) => {
        notificationService.showSave(result.resource);
        const ids = (querySpace.tableRendered.value ?? []).map((row) => row.workPackageId);
        return apiv3Service
          .work_packages
          .filterUpdatedSince(ids, updatedAt)
          .get()
          .toPromise()
          .then(() => {
            halEvents.push(result.resource, { eventType: 'updated' });
            return querySpace.timelineRendered.pipe(take(1)).toPromise();
          });
      }));
  }
}
