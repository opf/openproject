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

import { TestBed, type ComponentFixture } from '@angular/core/testing';
import { type Mock } from 'vitest';
import { BrowserDetector } from 'core-app/core/browser/browser-detector.service';
import { GridWidgetsService } from 'core-app/shared/components/grids/widgets/widgets.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { clearSelectionOnEscape } from 'core-common/selection-escape';
import { GridComponent } from './grid.component';
import { GridAddWidgetService } from './add-widget.service';
import { GridAreaService } from './area.service';
import { GridDragAndDropService } from './drag-and-drop.service';
import { GridRemoveWidgetService } from './remove-widget.service';
import { GridResizeService } from './resize.service';

describe('GridComponent', () => {
  let fixture:ComponentFixture<GridComponent>;
  let drag:{ currentlyDragging:boolean; abort:Mock<() => void> };
  let resize:{ currentlyResizing:boolean; abort:Mock<() => void> };
  let clear:Mock<() => void>;
  let selectionListener:(event:Event) => void;

  beforeEach(() => {
    drag = { currentlyDragging: false, abort: vi.fn(() => { drag.currentlyDragging = false; }) };
    resize = { currentlyResizing: false, abort: vi.fn(() => { resize.currentlyResizing = false; }) };
    TestBed.configureTestingModule({
      declarations: [GridComponent],
      providers: [
        { provide: GridDragAndDropService, useValue: drag },
        { provide: GridResizeService, useValue: resize },
        { provide: GridAreaService, useValue: {} },
        { provide: GridAddWidgetService, useValue: {} },
        { provide: GridRemoveWidgetService, useValue: {} },
        { provide: GridWidgetsService, useValue: {} },
        { provide: BrowserDetector, useValue: {} },
      ],
    }).overrideTemplate(GridComponent, '');
    fixture = TestBed.createComponent(GridComponent);
    fixture.componentInstance.grid = {} as GridResource;
    fixture.detectChanges();

    clear = vi.fn();
    selectionListener = (event) => clearSelectionOnEscape(event as KeyboardEvent, () => true, clear);
    document.addEventListener('keydown', selectionListener);
  });

  afterEach(() => {
    document.removeEventListener('keydown', selectionListener);
    fixture.destroy();
  });

  function escape(type:'keydown'|'keyup', target:EventTarget = document.body):KeyboardEvent {
    const event = new KeyboardEvent(type, { key: 'Escape', bubbles: true, cancelable: true });
    target.dispatchEvent(event);
    return event;
  }

  describe.each([
    ['a widget drag', () => { drag.currentlyDragging = true; }, () => drag.abort],
    ['a widget resize', () => { resize.currentlyResizing = true; }, () => resize.abort],
  ])('during %s', (_name, start, abort) => {
    it('keeps the Escape keydown from clearing selections, cancels on keyup and frees the next Escape', () => {
      start();
      const button = document.createElement('button');
      document.body.appendChild(button);

      try {
        const keydown = escape('keydown', button);
        expect(keydown.defaultPrevented).toBe(true);
        expect(clear).not.toHaveBeenCalled();

        escape('keyup', button);
        expect(abort()).toHaveBeenCalledOnce();

        escape('keydown', button);
        expect(clear).toHaveBeenCalledOnce();
      } finally {
        button.remove();
      }
    });
  });

  it('leaves Escape to the selections while idle', () => {
    const keydown = escape('keydown');

    expect(keydown.defaultPrevented).toBe(true);
    expect(clear).toHaveBeenCalledOnce();
    expect(drag.abort).not.toHaveBeenCalled();
  });

  it('stops owning Escape once destroyed', () => {
    fixture.destroy();
    drag.currentlyDragging = true;

    escape('keydown');

    expect(clear).toHaveBeenCalledOnce();
  });
});
