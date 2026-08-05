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

// The drag preview's `getOffset` decides where the pointer sits on the
// preview, and Pragmatic only hands it to the real `setCustomNativeDragPreview`
// — nothing observable from the outside. So this file mocks that module and
// reads the options back. It stays a separate file from the sibling engine
// spec because that one renders previews for real, and one file cannot both
// stub and exercise the same module.

import { vi } from 'vitest';
import { NativeDragSimulation } from 'core-common/drag-and-drop/testing/native-drag-simulation';
import type { createSortableRoot as createSortableRootFn } from './sortable-lists-engine';

// `doMock` is not hoisted, so this initialises before the factory below runs
// and a plain const does the job `vi.hoisted()` used to.
const previewCalls:{
  getOffset?:(args:{ container:HTMLElement }) => { x:number; y:number };
}[] = [];

vi.doMock('@atlaskit/pragmatic-drag-and-drop/element/set-custom-native-drag-preview', () => ({
  setCustomNativeDragPreview: (options:{
    getOffset?:(args:{ container:HTMLElement }) => { x:number; y:number };
  }) => {
    previewCalls.push(options);
  },
}));

let createSortableRoot:typeof createSortableRootFn;

describe('createSortableRoot drag preview offset', () => {
  let cleanupFns:(() => void)[] = [];

  beforeAll(async () => {
    ({ createSortableRoot } = await import('./sortable-lists-engine'));
  });

  beforeEach(() => { previewCalls.length = 0; });

  afterEach(() => {
    cleanupFns.forEach((fn) => fn());
    cleanupFns = [];
    document.body.replaceChildren();
  });

  function setup():{ rows:HTMLElement[] } {
    const root = document.createElement('div');
    // The engine attaches auto-scroll to this element directly, with no
    // ancestor walk, so the overflow has to sit here. This also computes
    // overflow-x to auto; 600px rows just happen to fit the viewport.
    root.style.cssText = 'overflow-y:auto;';
    const rows = ['a', 'b'].map((id) => {
      const row = document.createElement('div');
      row.style.cssText = 'height:40px; width:600px;';
      row.textContent = id;
      root.appendChild(row);
      return row;
    });
    document.body.appendChild(root);

    const sortableRoot = createSortableRoot({
      element: root,
      preview: ({ container }) => {
        container.append(document.createElement('div'));
      },
      onDrop: () => undefined,
    });

    const listCleanup = sortableRoot.registerList({ element: root, listId: 'l1' });
    const itemCleanups = rows.map((row, index) => sortableRoot.registerItem({
      element: row,
      itemId: ['a', 'b'][index],
      listId: 'l1',
    }));
    cleanupFns.push(listCleanup, ...itemCleanups, () => sortableRoot.destroy());

    return { rows };
  }

  it('keeps the pointer where it was pressed on the source', async () => {
    const { rows } = setup();
    const sourceRect = rows[0].getBoundingClientRect();
    const grab = { x: sourceRect.left + 12, y: sourceRect.top + 18 };

    const simulation = new NativeDragSimulation(rows[0]);
    await simulation.start(grab);

    expect(previewCalls).toHaveLength(1);
    const { getOffset } = previewCalls[0];
    expect(getOffset).toBeTypeOf('function');

    // A container at least as large as the grab offset, so nothing is clamped.
    const container = document.createElement('div');
    container.style.cssText = 'position:fixed; top:0; left:0; width:500px; height:40px;';
    document.body.appendChild(container);

    expect(getOffset!({ container })).toEqual({ x: 12, y: 18 });

    await simulation.cancel();
  });

  it('clamps the offset to the preview so the pointer stays on it', async () => {
    const { rows } = setup();
    const sourceRect = rows[0].getBoundingClientRect();
    const grab = { x: sourceRect.left + 400, y: sourceRect.top + 30 };

    const simulation = new NativeDragSimulation(rows[0]);
    await simulation.start(grab);

    // The preview is far narrower than the 600px source row, so an unclamped
    // x of 400 would put the pointer past its right edge.
    const container = document.createElement('div');
    container.style.cssText = 'position:fixed; top:0; left:0; width:100px; height:20px;';
    document.body.appendChild(container);

    expect(previewCalls[0].getOffset!({ container })).toEqual({ x: 100, y: 20 });

    await simulation.cancel();
  });
});
