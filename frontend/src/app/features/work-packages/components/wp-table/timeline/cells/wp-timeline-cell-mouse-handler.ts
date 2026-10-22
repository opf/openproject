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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
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
import { lastValueFrom } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { onDestroySafely, runCleanup } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageCellLabels } from './wp-timeline-cell-labels';
import {
  MouseDirection,
  TimelineCellRenderer,
} from './timeline-cell-renderer';
import { RenderInfo } from '../wp-timeline';
import { WorkPackageTimelineTableController } from '../container/wp-timeline-container.directive';

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
  renderInfo:RenderInfo):() => void {
  const table = workPackageTimeline.workPackageTable;
  const tableDestroyRef = table.destroyRef;
  let disposed = false;
  const alive = () => !disposed && !workPackageTimeline.destroyRef.destroyed
    && !tableDestroyRef.destroyed && workPackageTimeline.workPackageTable === table;
  if (!alive()) return () => undefined;

  const bodyCleanups:(() => void)[] = [];
  const cellCleanups = new Map<string, () => void>();
  const cellHandlers = new Map<string, (event:MouseEvent) => void>();
  const listenBody = <K extends keyof HTMLElementEventMap>(type:K, callback:(event:HTMLElementEventMap[K]) => void) => {
    const listener = callback;
    document.body.addEventListener(type, listener);
    bodyCleanups.push(() => document.body.removeEventListener(type, listener));
  };
  const assignCell = (
    key:'onmousemove'|'onmousedown'|'onmouseup'|'onmouseleave',
    callback:(event:MouseEvent) => void,
  ) => {
    const listener = (event:MouseEvent) => { if (alive()) callback(event); };
    cell[key] = listener;
    cellHandlers.set(key, listener);
    cellCleanups.set(key, () => { if (cell[key] === listener) cell[key] = null; });
  };
  const clearBody = () => bodyCleanups.splice(0).forEach((cleanup) => runCleanup(cleanup));
  const resource = renderInfo.workPackage;
  const originalPointerEvents = bar.style.pointerEvents;
  const originalCursor = cell.style.cursor;
  let assignedCursor:string|undefined;
  const setCursor = (cursor:string) => { cell.style.cursor = cursor; assignedCursor = cursor; };

  let gestureActive = false;
  let mouseDownStartDay:number|null = null; // also flag to signal active drag'n'drop
  renderInfo.change = halEditing.changeFor(renderInfo.workPackage);

  let placeholderForEmptyCell:HTMLElement;

  // handles change to existing work packages
  const barMouseDown = (ev:MouseEvent) => {
    if (!alive()) return;
    if (!ev.button || ev.button === 0) {
      // Left click only
      workPackageMouseDownFn(ev);
    }
  };

  // handles initial creation of start/due values
  assignCell('onmousemove', handleMouseMoveOnEmptyCell);

  bar.addEventListener('mousedown', barMouseDown);
  let releaseController:() => void = () => undefined;
  let releaseTable:() => void = () => undefined;
  function clearInput() {
    clearBody();
    runCleanup(() => placeholderForEmptyCell?.remove());
    runCleanup(() => bar.classList.remove('active-drag'));
    runCleanup(() => { bar.style.pointerEvents = originalPointerEvents; });
    if (gestureActive && workPackageTimeline.workPackageTable === table) {
      runCleanup(() => workPackageTimeline.resetCursor());
    }
    gestureActive = false;
    if (assignedCursor !== undefined && cell.style.cursor === assignedCursor
      && cell.onmousemove === cellHandlers.get('onmousemove')) {
      runCleanup(() => { cell.style.cursor = originalCursor; });
    }
    if (workPackageTimeline.workPackageTable === table) workPackageTimeline.disableViewParamsCalculation = false;
    mouseDownStartDay = null;
  }
  const dispose = () => {
    if (disposed) return;
    disposed = true;
    clearInput();
    cellCleanups.forEach((cleanup) => runCleanup(cleanup));
    cellCleanups.clear();
    cellHandlers.clear();
    runCleanup(() => bar.removeEventListener('mousedown', barMouseDown));
    if (!workPackageTimeline.destroyRef.destroyed) runCleanup(releaseController);
    if (!tableDestroyRef.destroyed) runCleanup(releaseTable);
  };
  releaseController = onDestroySafely(workPackageTimeline.destroyRef, dispose);
  releaseTable = onDestroySafely(tableDestroyRef, dispose);

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
    if (!alive()) return;
    ev.preventDefault();

    // add/remove css class while drag'n'drop is active
    const classNameActiveDrag = 'active-drag';
    bar.classList.add(classNameActiveDrag);

    workPackageTimeline.disableViewParamsCalculation = true;
    mouseDownStartDay = getCursorOffsetInDaysFromLeft(ev);
    gestureActive = true;

    // If this wp is a parent element, changing it is not allowed
    // if it is not on 'Manual scheduling' mode
    // But adding a relation to it is.
    if (!renderInfo.workPackage.isLeaf && !renderInfo.viewParams.activeSelectionMode && !renderInfo.workPackage.scheduleManually) {
      listenBody('mouseup', () => { if (alive()) clearInput(); });
      return;
    }

    // Determine what attributes of the work package should be changed
    const direction = renderer.onMouseDown(ev, null, renderInfo, labels);

    listenBody('mousemove', createMouseMoveFn(direction));
    listenBody('keydown', consumeEscape);
    listenBody('keyup', keyPressFn);
    listenBody('mouseup', () => deactivate(direction, false));
  }

  function createMouseMoveFn(direction:MouseDirection) {
    return (ev:MouseEvent) => {
      if (!alive()) return;
      const days = getCursorOffsetInDaysFromLeft(ev) - (mouseDownStartDay!);
      const offsetDayCurrent = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);
      const dayUnderCursor = renderInfo.viewParams.dateDisplayStart.clone().add(offsetDayCurrent, 'days');

      applyRendererMoveChanges(dayUnderCursor, days, direction);
    };
  }

  // Cancellation happens on keyup; the keydown half would otherwise clear
  // the row selection first.
  function consumeEscape(kev:KeyboardEvent) {
    if (!alive()) return;
    if (kev.key === 'Escape') {
      kev.preventDefault();
    }
  }

  function keyPressFn(kev:KeyboardEvent) {
    if (!alive()) return;
    if (kev.key === 'Escape') {
      deactivate(null, true);
    }
  }

  function handleMouseMoveOnEmptyCell(ev:MouseEvent) {
    if (!alive()) return;
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
      setCursor('not-allowed');
      return;
    }

    // display placeholder only if the timeline is editable
    setCursor('');
    cell.appendChild(placeholderForEmptyCell);

    // abort if mouse leaves cell
    assignCell('onmouseleave', () => {
      placeholderForEmptyCell.remove();
    });

    // create logic
    assignCell('onmousedown', (evt) => {
      placeholderForEmptyCell.remove();

      evt.preventDefault();

      if (renderer.cursorOrDatesAreNonWorking(evt, renderInfo)) {
        return;
      }

      gestureActive = true;
      bar.style.pointerEvents = 'none';

      const [clickStart, offsetDayStart] = renderer.cursorDateAndDayOffset(evt, renderInfo);
      const dateForCreate = clickStart.format('YYYY-MM-DD');
      const direction = renderer.onMouseDown(evt, dateForCreate, renderInfo, labels);
      renderer.update(bar, labels, renderInfo);

      if (direction === 'create') {
        deactivate(direction, false);
        return;
      }

      listenBody('mousemove', mouseMoveOnEmptyCellFn(offsetDayStart, direction));
      listenBody('mouseup', () => deactivate(direction, false));

      assignCell('onmouseup', () => {
        deactivate(direction, false);
      });

      listenBody('keydown', consumeEscape);
      listenBody('keyup', keyPressFn);
    });
  }

  function mouseMoveOnEmptyCellFn(offsetDayStart:number, mouseDownType:MouseDirection) {
    return (ev:MouseEvent) => {
      if (!alive()) return;
      placeholderForEmptyCell.remove();
      const relativePosition = Math.abs(cell.getBoundingClientRect().x - ev.clientX);
      const offsetDayCurrent = Math.floor(relativePosition / renderInfo.viewParams.pixelPerDay);
      const dayUnderCursor = renderInfo.viewParams.dateDisplayStart.clone().add(offsetDayCurrent, 'days');
      const widthInDays = offsetDayCurrent - offsetDayStart;

      applyRendererMoveChanges(dayUnderCursor, widthInDays, mouseDownType);
    };
  }

  function deactivate(direction:MouseDirection|null, cancelled:boolean) {
    if (!alive()) return;
    const change = renderInfo.change;
    clearInput();
    assignCell('onmousemove', handleMouseMoveOnEmptyCell);
    assignCell('onmousedown', () => undefined);
    assignCell('onmouseleave', () => undefined);
    assignCell('onmouseup', () => undefined);

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
        if (!alive()) return;
        renderInfo.change.clear();
        renderer.onMouseDownEnd(labels, renderInfo.change);
      })
      .catch((error) => {
        notificationService.handleRawError(error, resource);
        if (alive()) cancelChange();
      });
  }

  function cancelChange() {
    if (!alive()) return;
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
    const ids = (querySpace.tableRendered.value ?? []).map((row) => row.workPackageId);

    return (loadingIndicator.table.promise = halEditing
      .save<WorkPackageResource, WorkPackageChangeset>(change)
      .then((result) => {
        notificationService.showSave(result.resource);
        return apiv3Service
          .work_packages
          .filterUpdatedSince(ids, updatedAt)
          .get()
          .toPromise()
          .then(async () => {
            halEvents.push(result.resource, { eventType: 'updated' });
            if (alive()) {
              await lastValueFrom(querySpace.timelineRendered.pipe(
                take(1),
                takeUntilDestroyed(workPackageTimeline.destroyRef),
                takeUntilDestroyed(tableDestroyRef),
              ), { defaultValue: null });
            }
          });
      }));
  }
  return dispose;
}
