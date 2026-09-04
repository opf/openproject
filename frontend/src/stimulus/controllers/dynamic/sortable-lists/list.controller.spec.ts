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

vi.mock('@atlaskit/pragmatic-drag-and-drop/element/adapter', () => ({
  draggable: vi.fn(() => vi.fn()),
  dropTargetForElements: vi.fn(() => vi.fn()),
  monitorForElements: vi.fn(() => vi.fn()),
}));

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
    { busy = false } = {},
  ):SortableListsRoot {
    return {
      element,
      busy,
      moveInDirection: vi.fn(),
      moveAvailability: vi.fn(() => null),
      ownerListElementOf: vi.fn(() => null),
      ownerRowsContainer: vi.fn(() => null),
      freezeDragBatch: vi.fn(() => 1),
      markDragBatch: vi.fn(),
      dragConfined: vi.fn(() => false),
    };
  }

  async function connectedListFor({
    type = 'sprint',
    id = '7',
    dropPosition = null,
    acceptedType = 'work_package',
    root = fakeRoot(),
  }:{
    type?:string|null;
    id?:string|null;
    dropPosition?:string|null;
    acceptedType?:string|null;
    root?:SortableListsRoot|null;
  } = {}) {
    fixture.innerHTML = `
      <ul data-controller="sortable-lists--list"
          ${type != null ? `data-sortable-lists--list-type-value="${type}"` : ''}
          ${id != null ? `data-sortable-lists--list-id-value="${id}"` : ''}
          ${acceptedType != null ? `data-sortable-lists--list-accepted-type-value="${acceptedType}"` : ''}
          ${dropPosition != null ? `data-sortable-lists--list-drop-position-value="${dropPosition}"` : ''}></ul>
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

  function source(
    rootElement:HTMLElement|null,
    type = 'work_package',
    { confined = false, sourceListElement = null }:{ confined?:boolean; sourceListElement?:HTMLElement|null } = {},
  ) {
    return {
      data: sortableItemData({ itemId: '1', type, rootElement, confined, sourceListElement }),
      element: document.createElement('li'),
    } as never;
  }

  function locationOver(...dropTargets:{ data:Record<string|symbol, unknown> }[]) {
    return { current: { dropTargets } } as never;
  }

  it('registers itself as a drop target', async () => {
    const { list } = await connectedListFor();

    expect(dropTargetForElements).toHaveBeenCalledWith(expect.objectContaining({ element: list }));
  });

  it('drops the previous registration and registers again on reregister', async () => {
    const { list, controller } = await connectedListFor();

    controller.reregister();

    expect(vi.mocked(dropTargetForElements).mock.calls.filter(([options]) => options.element === list)).toHaveLength(2);
  });

  it('stays inert on reregister for a display-only list', async () => {
    const { list, controller } = await connectedListFor({ acceptedType: null });

    controller.reregister();

    expect(vi.mocked(dropTargetForElements).mock.calls.filter(([options]) => options.element === list)).toHaveLength(0);
  });

  it('does not register without an accepted type', async () => {
    const { list } = await connectedListFor({ acceptedType: null, root: null });

    expect(dropTargetForElements).not.toHaveBeenCalledWith(expect.objectContaining({ element: list }));
  });

  it('warns and does not register when it accepts a type but has no list type', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);

    const { list } = await connectedListFor({ type: null, acceptedType: 'work_package', root: null });

    expect(warn).toHaveBeenCalledWith(expect.stringContaining('type'), expect.anything());
    expect(dropTargetForElements).not.toHaveBeenCalledWith(expect.objectContaining({ element: list }));

    warn.mockRestore();
  });

  it('exposes its list payload through getData', async () => {
    const { list } = await connectedListFor({ type: 'sprint', id: '7' });

    expect(dropTargetOptionsFor(list)?.getData?.({ element: list, input: {} as never, source: source(null) }))
      .toEqual(expect.objectContaining({ type: 'sprint', listId: '7' }));
  });

  it('resolves the child <ul> as the rows container on the payload', async () => {
    fixture.innerHTML = `
      <div data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-accepted-type-value="work_package">
        <ul></ul>
      </div>
    `;
    const list = fixture.querySelector<HTMLElement>('[data-controller~="sortable-lists--list"]')!;
    await ctx.nextFrame();
    const rows = list.querySelector('ul')!;

    expect(dropTargetOptionsFor(list)?.getData?.({ element: list, input: {} as never, source: source(null) }))
      .toEqual(expect.objectContaining({ rowsContainer: rows }));
  });

  it('falls back to the list element as the rows container when there is no child <ul>', async () => {
    const { list } = await connectedListFor({ type: 'sprint', id: '7' });

    expect(dropTargetOptionsFor(list)?.getData?.({ element: list, input: {} as never, source: source(null) }))
      .toEqual(expect.objectContaining({ rowsContainer: list }));
  });

  it('defaults its list-only drop position to end', async () => {
    const { list } = await connectedListFor({ type: 'sprint', id: '7' });

    expect(dropTargetOptionsFor(list)?.getData?.({ element: list, input: {} as never, source: source(null) }))
      .toEqual(expect.objectContaining({ dropPosition: 'end' }));
  });

  it('exposes the configured list-only drop position', async () => {
    const { list } = await connectedListFor({ type: 'sprint', id: '7', dropPosition: 'start' });

    expect(dropTargetOptionsFor(list)?.getData?.({ element: list, input: {} as never, source: source(null) }))
      .toEqual(expect.objectContaining({ dropPosition: 'start' }));
  });

  it('falls back to end for an unknown drop position value', async () => {
    const { list } = await connectedListFor({ type: 'sprint', id: '7', dropPosition: 'sideways' });

    expect(dropTargetOptionsFor(list)?.getData?.({ element: list, input: {} as never, source: source(null) }))
      .toEqual(expect.objectContaining({ dropPosition: 'end' }));
  });

  it('accepts a same-root item of the accepted type', async () => {
    const root = document.createElement('div');
    const { list } = await connectedListFor({ acceptedType: 'work_package', root: fakeRoot(root) });

    expect(dropTargetOptionsFor(list)?.canDrop?.({ element: list, input: {} as never, source: source(root, 'work_package') }))
      .toBe(true);
  });

  // A confined item stays accepted by a foreign list on purpose: only an
  // accepted target keeps the standard 'move' cursor on the dragover (refused,
  // Chrome falls back to a copy cursor), and Pragmatic's getDropEffect cannot
  // express 'none'. The refusal lives in resolveDropIntent and in the
  // suppressed drop indicators instead.
  it('still accepts a confined item from another list', async () => {
    const root = document.createElement('div');
    const { list } = await connectedListFor({ acceptedType: 'work_package', root: fakeRoot(root) });

    expect(dropTargetOptionsFor(list)?.canDrop?.({
      element: list,
      input: {} as never,
      source: source(root, 'work_package', { confined: true, sourceListElement: document.createElement('ul') }),
    })).toBe(true);
  });

  it('rejects an item whose type is not accepted', async () => {
    const root = document.createElement('div');
    const { list } = await connectedListFor({ acceptedType: 'work_package', root: fakeRoot(root) });

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

  it('outlines the container for a list-only drop', async () => {
    const rootElement = document.createElement('div');
    const { list } = await connectedListFor({ root: fakeRoot(rootElement) });
    const options = dropTargetOptionsFor(list);

    options?.onDragEnter?.({ location: locationOver(), source: source(rootElement) } as never);

    expect(list.dataset.dropContainer).toEqual('active');
  });

  it('does not outline the container while the pointer is over an item row', async () => {
    const rootElement = document.createElement('div');
    const { list } = await connectedListFor({ root: fakeRoot(rootElement) });
    const options = dropTargetOptionsFor(list);

    options?.onDrag?.({
      location: locationOver({ data: sortableItemData({ itemId: '1', type: 'work_package', rootElement: null }) }),
      source: source(rootElement),
    } as never);

    expect(list.dataset.dropContainer).toBeUndefined();
  });

  it('marks the container refused for a confined item from another list', async () => {
    const rootElement = document.createElement('div');
    const { list } = await connectedListFor({ root: fakeRoot(rootElement) });
    const options = dropTargetOptionsFor(list);

    options?.onDragEnter?.({
      location: locationOver(),
      source: source(rootElement, 'work_package', { confined: true, sourceListElement: document.createElement('ul') }),
    } as never);

    expect(list.dataset.dropContainer).toEqual('refused');
  });

  it('outlines the container for a confined item over its own list', async () => {
    const rootElement = document.createElement('div');
    const { list } = await connectedListFor({ root: fakeRoot(rootElement) });
    const options = dropTargetOptionsFor(list);

    options?.onDragEnter?.({
      location: locationOver(),
      source: source(rootElement, 'work_package', { confined: true, sourceListElement: list }),
    } as never);

    expect(list.dataset.dropContainer).toEqual('active');
  });

  it('clears the refused mark on drag leave', async () => {
    const rootElement = document.createElement('div');
    const { list } = await connectedListFor({ root: fakeRoot(rootElement) });
    const options = dropTargetOptionsFor(list);

    options?.onDragEnter?.({
      location: locationOver(),
      source: source(rootElement, 'work_package', { confined: true, sourceListElement: document.createElement('ul') }),
    } as never);
    expect(list.dataset.dropContainer).toEqual('refused');

    options?.onDragLeave?.({} as never);
    expect(list.dataset.dropContainer).toBeUndefined();
  });

  it('clears the container outline when the pointer moves from the list onto an item row', async () => {
    const rootElement = document.createElement('div');
    const { list } = await connectedListFor({ root: fakeRoot(rootElement) });
    const options = dropTargetOptionsFor(list);

    options?.onDragEnter?.({ location: locationOver(), source: source(rootElement) } as never);
    expect(list.dataset.dropContainer).toEqual('active');

    options?.onDrag?.({
      location: locationOver({ data: sortableItemData({ itemId: '1', type: 'work_package', rootElement: null }) }),
      source: source(rootElement),
    } as never);
    expect(list.dataset.dropContainer).toBeUndefined();
  });

  it('clears the container outline on drag leave', async () => {
    const rootElement = document.createElement('div');
    const { list } = await connectedListFor({ root: fakeRoot(rootElement) });
    const options = dropTargetOptionsFor(list);

    options?.onDragEnter?.({ location: locationOver(), source: source(rootElement) } as never);
    expect(list.dataset.dropContainer).toEqual('active');

    options?.onDragLeave?.({} as never);
    expect(list.dataset.dropContainer).toBeUndefined();
  });

  it('rejects drops while the root is busy', async () => {
    const root = document.createElement('div');
    const { list } = await connectedListFor({ root: fakeRoot(root, { busy: true }) });

    expect(dropTargetOptionsFor(list)?.canDrop?.({ element: list, input: {} as never, source: source(root, 'work_package') }))
      .toBe(false);
  });
});
