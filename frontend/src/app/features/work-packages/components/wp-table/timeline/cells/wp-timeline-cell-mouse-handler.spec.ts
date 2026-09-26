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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import moment from 'moment';
import { fireEvent } from '@testing-library/dom';
import { type Mock } from 'vitest';
import { clearSelectionOnEscape } from 'core-common/selection-escape';
import { registerWorkPackageMouseHandler } from './wp-timeline-cell-mouse-handler';
import { TimelineCellRenderer } from './timeline-cell-renderer';
import { WorkPackageCellLabels } from './wp-timeline-cell-labels';
import { RenderInfo } from '../wp-timeline';
import { WorkPackageTimelineTableController } from '../container/wp-timeline-container.directive';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { target } from 'core-app/shared/helpers/event-helpers';

describe('registerWorkPackageMouseHandler', () => {
  let cell:HTMLElement;
  let bar:HTMLDivElement;
  let change:{ clear:Mock<() => void>; isEmpty:() => boolean; projectedResource:Record<string, string>; pristineResource:Record<string, string|null> };
  let renderer:Record<string, Mock>;
  let save:Mock<() => void>;
  let clear:Mock<() => void>;
  let selectionListener:(event:Event) => void;

  beforeEach(() => {
    cell = document.createElement('div');
    bar = document.createElement('div');
    cell.appendChild(bar);
    document.body.appendChild(cell);

    change = {
      clear: vi.fn(),
      isEmpty: () => false,
      projectedResource: { startDate: '2026-01-05', dueDate: '2026-01-06' },
      pristineResource: { duration: null },
    };
    renderer = {
      onMouseDown: vi.fn(() => 'both'),
      onDaysMoved: vi.fn(),
      assignDateValues: vi.fn(),
      update: vi.fn(),
      onMouseDownEnd: vi.fn(),
      isEmpty: vi.fn(() => true),
      displayPlaceholderUnderCursor: vi.fn(() => document.createElement('div')),
      canMoveDates: vi.fn(() => true),
      cursorOrDatesAreNonWorking: vi.fn(() => false),
      cursorDateAndDayOffset: vi.fn(() => [moment('2026-01-05'), 0]),
    };
    save = vi.fn();
    const renderInfo = {
      workPackage: { isLeaf: true, scheduleManually: false },
      viewParams: { pixelPerDay: 10, dateDisplayStart: moment('2026-01-01'), activeSelectionMode: null },
    } as unknown as RenderInfo;
    const timeline = {
      disableViewParamsCalculation: false,
      getAbsoluteLeftCoordinates: () => 0,
      resetCursor: vi.fn(),
      refreshView: vi.fn(),
    } as unknown as WorkPackageTimelineTableController;

    registerWorkPackageMouseHandler(
      { get: vi.fn() },
      () => renderInfo,
      timeline,
      { changeFor: () => change, save } as unknown as HalResourceEditingService,
      {} as HalEventsService,
      {} as WorkPackageNotificationService,
      {} as LoadingIndicatorService,
      cell,
      bar,
      {} as WorkPackageCellLabels,
      renderer as unknown as TimelineCellRenderer,
      renderInfo,
    );

    clear = vi.fn();
    selectionListener = (event) => clearSelectionOnEscape(event as KeyboardEvent, () => true, clear);
    document.addEventListener('keydown', selectionListener);
  });

  afterEach(() => {
    document.removeEventListener('keydown', selectionListener);
    target(document.body).off('.timelinecell');
    target(document.body).off('.emptytimelinecell');
    cell.remove();
  });

  const escape = { key: 'Escape' };

  function startBarDrag() {
    fireEvent.mouseDown(bar, { button: 0, clientX: 0 });
  }

  function startEmptyCellDrag() {
    fireEvent.mouseMove(cell, { clientX: 0 });
    fireEvent.mouseDown(cell, { button: 0, clientX: 0 });
  }

  describe.each([
    ['an existing bar', () => startBarDrag()],
    ['an empty cell', () => startEmptyCellDrag()],
  ])('while dragging %s', (_name, startDrag) => {
    it('keeps the Escape keydown from clearing the selection', () => {
      startDrag();

      expect(fireEvent.keyDown(document.body, escape)).toBe(false);
      expect(clear).not.toHaveBeenCalled();
    });

    it('still cancels the drag on keyup and frees the next Escape', () => {
      startDrag();
      fireEvent.keyDown(document.body, escape);

      fireEvent.keyUp(document.body, escape);
      expect(change.clear).toHaveBeenCalledOnce();
      expect(renderer.onMouseDownEnd).toHaveBeenCalledOnce();
      expect(save).not.toHaveBeenCalled();

      fireEvent.keyDown(document.body, escape);
      expect(clear).toHaveBeenCalledOnce();
    });
  });

  it('lets Escape clear the selection when no drag is active', () => {
    expect(fireEvent.keyDown(document.body, escape)).toBe(false);
    expect(clear).toHaveBeenCalledOnce();
  });
});
