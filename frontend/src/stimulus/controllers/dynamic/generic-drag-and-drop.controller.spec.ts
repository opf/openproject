/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import GenericDragAndDropController from './generic-drag-and-drop.controller';
import { createControllerInstance } from 'core-stimulus/test-helpers';

describe('GenericDragAndDropController', () => {
  let controller:GenericDragAndDropController;

  beforeEach(() => {
    controller = createControllerInstance(GenericDragAndDropController);
  });

  function setValue(name:'handleValue' | 'handleSelectorValue', value:boolean | string) {
    Object.defineProperty(controller, name, { value, configurable: true });
  }

  function draggableRow() {
    const row = document.createElement('li');
    row.className = 'Box-row Box-row--draggable';
    row.tabIndex = 0;
    row.dataset.draggableId = '42';
    row.dataset.draggableType = 'story';
    row.dataset.dropUrl = '/drop';
    return row;
  }

  function callCanStartDrag(el:Element | null | undefined, handle:Element | null | undefined):boolean {
    const canStartDrag = Reflect.get(controller, 'canStartDrag') as (this:GenericDragAndDropController, el:Element | null | undefined, handle:Element | null | undefined) => boolean;

    return canStartDrag.call(controller, el, handle);
  }

  function callAriaPressedTarget(el:Element):Element | null {
    const ariaPressedTarget = Reflect.get(controller, 'ariaPressedTarget') as (this:GenericDragAndDropController, el:Element) => Element | null;

    return ariaPressedTarget.call(controller, el);
  }

  describe('canStartDrag', () => {
    it('allows dragging a draggable row in handle-less mode', () => {
      const row = draggableRow();

      setValue('handleValue', false);
      setValue('handleSelectorValue', '.DragHandle');

      expect(callCanStartDrag(row, row)).toBe(true);
    });

    it('rejects rows that are not draggable in handle-less mode', () => {
      const row = document.createElement('li');
      row.className = 'Box-row';
      row.tabIndex = 0;

      setValue('handleValue', false);
      setValue('handleSelectorValue', '.DragHandle');

      expect(callCanStartDrag(row, row)).toBe(false);
    });

    it('rejects empty placeholder rows in handle-less mode', () => {
      const row = draggableRow();
      row.dataset.emptyListItem = 'true';

      setValue('handleValue', false);
      setValue('handleSelectorValue', '.DragHandle');

      expect(callCanStartDrag(row, row)).toBe(false);
    });

    it('rejects interactive descendants in handle-less mode', () => {
      const row = draggableRow();
      const button = document.createElement('button');
      row.appendChild(button);

      setValue('handleValue', false);
      setValue('handleSelectorValue', '.DragHandle');

      expect(callCanStartDrag(row, button)).toBe(false);
    });

    it('allows drag handles in handle mode', () => {
      const row = draggableRow();
      const handle = document.createElement('button');
      handle.className = 'DragHandle';
      row.appendChild(handle);

      setValue('handleValue', true);
      setValue('handleSelectorValue', '.DragHandle');

      expect(callCanStartDrag(row, handle)).toBe(true);
    });
  });

  describe('ariaPressedTarget', () => {
    it('returns null in handle-less mode', () => {
      const row = draggableRow();

      setValue('handleValue', false);
      setValue('handleSelectorValue', '.DragHandle');

      expect(callAriaPressedTarget(row)).toBeNull();
    });

    it('returns the handle element in handle mode', () => {
      const row = draggableRow();
      const handle = document.createElement('button');
      handle.className = 'DragHandle';
      row.appendChild(handle);

      setValue('handleValue', true);
      setValue('handleSelectorValue', '.DragHandle');

      expect(callAriaPressedTarget(row)).toBe(handle);
    });
  });
});
