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

import { waitFor } from '@testing-library/dom';
import { vi } from 'vitest';

import GenericDragAndDropController from './generic-drag-and-drop.controller';
import { createControllerInstance, setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';

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

  describe('autoscroll setup through the plugin context', () => {
    class FakeAutoscroll {
      static constructedWith:unknown[][] = [];

      static instances:FakeAutoscroll[] = [];

      destroy = vi.fn();

      constructor(...args:unknown[]) {
        FakeAutoscroll.constructedWith.push(args);
        FakeAutoscroll.instances.push(this);
      }
    }

    let ctx:StimulusTestContext;
    let originalOpenProject:typeof window.OpenProject;

    const pluginContext = () => ({ classes: { DomAutoscrollService: FakeAutoscroll } });

    beforeEach(async () => {
      FakeAutoscroll.constructedWith = [];
      FakeAutoscroll.instances = [];
      originalOpenProject = window.OpenProject;
      window.OpenProject = {
        getPluginContext: () => Promise.resolve(pluginContext()),
      } as unknown as typeof window.OpenProject;

      ctx = await setupStimulusTest({
        controllers: { 'generic-drag-and-drop': GenericDragAndDropController },
      });
    });

    afterEach(() => {
      ctx.dispose();
      window.OpenProject = originalOpenProject;
      vi.restoreAllMocks();
    });

    async function renderLists() {
      await ctx.mount(`
        <div data-controller="generic-drag-and-drop">
          <div data-generic-drag-and-drop-target="scrollContainer">
            <ul data-generic-drag-and-drop-target="container"></ul>
          </div>
        </div>
      `);
      return ctx.getController<GenericDragAndDropController>('generic-drag-and-drop');
    }

    it('exposes the full plugin context as a promise', async () => {
      const mounted = await renderLists();

      await expect(mounted.pluginContext).resolves.toMatchObject({
        classes: { DomAutoscrollService: FakeAutoscroll },
      });
    });

    it('sets up autoscroll on the scroll containers once connected', async () => {
      await renderLists();

      await waitFor(() => {
        expect(FakeAutoscroll.constructedWith).toHaveLength(1);
      });
      const scrollContainer = ctx.container.querySelector('[data-generic-drag-and-drop-target="scrollContainer"]');
      expect(FakeAutoscroll.constructedWith[0][0]).toEqual([scrollContainer]);
    });

    it('destroys the autoscroll instance on disconnect', async () => {
      await renderLists();
      const root = ctx.container.querySelector('[data-controller="generic-drag-and-drop"]')!;

      await waitFor(() => {
        expect(FakeAutoscroll.instances).toHaveLength(1);
      });

      root.remove();
      await ctx.nextFrame();

      expect(FakeAutoscroll.instances[0].destroy).toHaveBeenCalled();
    });

    it('does not set up autoscroll when disconnected before the context resolves', async () => {
      let resolveContext!:(context:unknown) => void;
      window.OpenProject = {
        getPluginContext: () => new Promise((resolve) => { resolveContext = resolve; }),
      } as unknown as typeof window.OpenProject;

      await renderLists();
      const root = ctx.container.querySelector('[data-controller="generic-drag-and-drop"]')!;

      root.remove();
      await ctx.nextFrame();

      resolveContext(pluginContext());
      await ctx.nextFrame();

      expect(FakeAutoscroll.constructedWith).toHaveLength(0);
    });
  });
});
