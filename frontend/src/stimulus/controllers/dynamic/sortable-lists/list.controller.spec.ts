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

import type { dropTargetForElements as dropTargetForElementsFn } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type ListControllerType from './list.controller';
import type { sortableItemData as sortableItemDataFn, SortableListsRoot } from './drag-and-drop';

// The list controller is tested in ISOLATION: the root drives the outlet
// hand-over in production (sortable-lists.controller.ts), so here we render only
// the list, let it connect, then call connectRoot(fakeRoot) ourselves to stand
// in for that wiring.
describe('Sortable lists list controller', () => {
  let dropTargetForElements:typeof dropTargetForElementsFn;
  let ListController:typeof ListControllerType;
  let sortableItemData:typeof sortableItemDataFn;

  let ctx:StimulusTestContext;
  let fixture:HTMLElement;

  beforeAll(async () => {
    vi.doMock('@atlaskit/pragmatic-drag-and-drop/element/adapter', () => ({
      draggable: vi.fn(() => vi.fn()),
      dropTargetForElements: vi.fn(() => vi.fn()),
      monitorForElements: vi.fn(() => vi.fn()),
    }));

    ({ dropTargetForElements } = await import('@atlaskit/pragmatic-drag-and-drop/element/adapter'));
    ({ default: ListController } = await import('./list.controller'));
    ({ sortableItemData } = await import('./drag-and-drop'));
  });

  beforeEach(async () => {
    vi.clearAllMocks();
    ctx = await setupStimulusTest({
      controllers: {
        'sortable-lists--list': ListController,
      },
    });
    fixture = ctx.container;
  });

  afterEach(() => ctx.dispose());

  function fakeRoot(
    element = document.createElement('div'),
    { moving = false, acceptedType = null as string|null } = {},
  ):SortableListsRoot {
    return { element, moving, acceptedType };
  }

  async function connectedListFor({
    type = 'sprint',
    id = '7',
    root = fakeRoot(),
  }:{
    type?:string|null;
    id?:string|null;
    root?:SortableListsRoot|null;
  } = {}) {
    fixture.innerHTML = `
      <ul data-controller="sortable-lists--list"
          ${type != null ? `data-sortable-lists--list-type-value="${type}"` : ''}
          ${id != null ? `data-sortable-lists--list-id-value="${id}"` : ''}></ul>
    `;
    const list = fixture.querySelector<HTMLElement>('[data-controller~="sortable-lists--list"]')!;
    await ctx.nextFrame();

    const controller = ctx.application.getControllerForElementAndIdentifier(list, 'sortable-lists--list') as unknown as InstanceType<typeof ListControllerType>;
    if (root) {
      controller.connectRoot(root);
    }

    return { list, controller };
  }

  function dropTargetOptionsFor(element:HTMLElement) {
    return vi.mocked(dropTargetForElements).mock.calls.find(([options]) => options.element === element)?.[0];
  }

  function source(rootElement:HTMLElement|null, type = 'work_package') {
    return {
      data: sortableItemData({ itemId: '1', type, rootElement }),
      element: document.createElement('li'),
    } as never;
  }

  it('registers itself as a drop target', async () => {
    const { list } = await connectedListFor();

    expect(dropTargetForElements).toHaveBeenCalledWith(expect.objectContaining({ element: list }));
  });

  it('does not register without a list type value', async () => {
    const { list } = await connectedListFor({ type: null, root: null });

    expect(dropTargetForElements).not.toHaveBeenCalledWith(expect.objectContaining({ element: list }));
  });

  it('exposes its list payload through getData', async () => {
    const { list } = await connectedListFor({ type: 'sprint', id: '7' });

    expect(dropTargetOptionsFor(list)?.getData?.({ element: list, input: {} as never, source: source(null) }))
      .toEqual(expect.objectContaining({ type: 'sprint', listId: '7' }));
  });

  it('accepts a same-root item of the accepted type', async () => {
    const root = document.createElement('div');
    const { list } = await connectedListFor({ root: fakeRoot(root, { acceptedType: 'work_package' }) });

    expect(dropTargetOptionsFor(list)?.canDrop?.({ element: list, input: {} as never, source: source(root, 'work_package') }))
      .toBe(true);
  });

  it('rejects an item whose type is not accepted', async () => {
    const root = document.createElement('div');
    const { list } = await connectedListFor({ root: fakeRoot(root, { acceptedType: 'work_package' }) });

    expect(dropTargetOptionsFor(list)?.canDrop?.({ element: list, input: {} as never, source: source(root, 'meeting_agenda_item') }))
      .toBe(false);
  });

  it('rejects a source from another root', async () => {
    const { list } = await connectedListFor({ root: fakeRoot(document.createElement('div')) });

    expect(dropTargetOptionsFor(list)?.canDrop?.({ element: list, input: {} as never, source: source(document.createElement('div'), 'work_package') }))
      .toBe(false);
  });

  it('rejects a source with no root reference', async () => {
    const { list } = await connectedListFor({ root: fakeRoot(document.createElement('div')) });

    expect(dropTargetOptionsFor(list)?.canDrop?.({ element: list, input: {} as never, source: source(null, 'work_package') }))
      .toBe(false);
  });

  it('refuses drops until the root reference is connected', async () => {
    const { list } = await connectedListFor({ root: null });

    expect(dropTargetOptionsFor(list)?.canDrop?.({ element: list, input: {} as never, source: source(document.createElement('div'), 'work_package') }))
      .toBe(false);
  });

  it('reflects the root moving state as aria-busy on connect', async () => {
    const { list } = await connectedListFor({ root: fakeRoot(document.createElement('div'), { moving: true }) });

    expect(list.getAttribute('aria-busy')).toEqual('true');
  });

  it('clears aria-busy when reflectMoving is turned off', async () => {
    const { list, controller } = await connectedListFor({ root: fakeRoot(document.createElement('div'), { moving: true }) });
    expect(list.getAttribute('aria-busy')).toEqual('true');

    controller.reflectMoving(false);
    expect(list.hasAttribute('aria-busy')).toBe(false);
  });

  it('clears aria-busy when the root outlet disconnects mid-move', async () => {
    const { list, controller } = await connectedListFor({ root: fakeRoot(document.createElement('div'), { moving: true }) });
    expect(list.getAttribute('aria-busy')).toEqual('true');

    controller.disconnectRoot();
    expect(list.hasAttribute('aria-busy')).toBe(false);
  });

  it('clears aria-busy when the list element disconnects mid-move', async () => {
    const { list } = await connectedListFor({ root: fakeRoot(document.createElement('div'), { moving: true }) });
    expect(list.getAttribute('aria-busy')).toEqual('true');

    list.remove();
    await ctx.nextFrame();
    expect(list.hasAttribute('aria-busy')).toBe(false);
  });

  it('rejects drops while the root is moving', async () => {
    const root = document.createElement('div');
    const { list } = await connectedListFor({ root: fakeRoot(root, { acceptedType: 'work_package', moving: true }) });

    expect(dropTargetOptionsFor(list)?.canDrop?.({ element: list, input: {} as never, source: source(root, 'work_package') }))
      .toBe(false);
  });
});
