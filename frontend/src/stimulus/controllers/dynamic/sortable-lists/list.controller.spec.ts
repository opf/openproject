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
import type SortableListsControllerType from '../sortable-lists.controller';
import type ListControllerType from './list.controller';
import type { sortableItemData as sortableItemDataFn } from './drag-and-drop';

// The list controller resolves its root through a real Stimulus outlet, so
// both the root (`sortable-lists.controller.ts`) and the list controller are
// registered here and wired together through the
// `data-sortable-lists--list-sortable-lists-outlet`
// attribute, exactly as production markup does.
describe('Sortable lists list controller', () => {
  let dropTargetForElements:typeof dropTargetForElementsFn;
  let ListController:typeof ListControllerType;
  let SortableListsController:typeof SortableListsControllerType;
  let sortableItemData:typeof sortableItemDataFn;

  let ctx:StimulusTestContext;
  let fixture:HTMLElement;

  beforeAll(async () => {
    vi.doMock('@atlaskit/pragmatic-drag-and-drop/element/adapter', () => ({
      draggable: vi.fn(() => vi.fn()),
      dropTargetForElements: vi.fn(() => vi.fn()),
      monitorForElements: vi.fn(() => vi.fn()),
    }));

    vi.doMock('@atlaskit/pragmatic-drag-and-drop-auto-scroll/element', () => ({
      autoScrollForElements: vi.fn(() => vi.fn()),
    }));

    ({ dropTargetForElements } = await import('@atlaskit/pragmatic-drag-and-drop/element/adapter'));
    ({ default: ListController } = await import('./list.controller'));
    ({ default: SortableListsController } = await import('../sortable-lists.controller'));
    ({ sortableItemData } = await import('./drag-and-drop'));
  });

  beforeEach(async () => {
    vi.clearAllMocks();
    ctx = await setupStimulusTest({
      controllers: {
        'sortable-lists': SortableListsController,
        'sortable-lists--list': ListController,
      },
    });
    fixture = ctx.container;
  });

  afterEach(() => ctx.dispose());

  async function connectedListFor({
    type = 'sprint',
    id = '7',
    dropPosition = null,
    acceptedTypes = ['work_package'],
    outlet = true,
  }:{
    type?:string|null;
    id?:string|null;
    dropPosition?:string|null;
    acceptedTypes?:string[]|null;
    outlet?:boolean;
  } = {}) {
    fixture.innerHTML = `
      <div id="root" data-controller="sortable-lists">
        <ul data-controller="sortable-lists--list"
            ${type != null ? `data-sortable-lists--list-type-value="${type}"` : ''}
            ${id != null ? `data-sortable-lists--list-id-value="${id}"` : ''}
            ${dropPosition != null ? `data-sortable-lists--list-drop-position-value="${dropPosition}"` : ''}
            ${acceptedTypes != null ? `data-sortable-lists--list-accepted-types-value='${JSON.stringify(acceptedTypes)}'` : ''}
            ${outlet ? 'data-sortable-lists--list-sortable-lists-outlet="#root"' : ''}></ul>
      </div>
    `;
    const root = fixture.querySelector<HTMLElement>('#root')!;
    const list = fixture.querySelector<HTMLElement>('[data-controller~="sortable-lists--list"]')!;
    await ctx.nextFrame();

    const controller = ctx.application.getControllerForElementAndIdentifier(list, 'sortable-lists--list') as unknown as InstanceType<typeof ListControllerType>;

    return { root, list, controller };
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

  function locationOver(...dropTargets:{ data:Record<string|symbol, unknown> }[]) {
    return { current: { dropTargets } } as never;
  }

  it('registers itself as a drop target', async () => {
    const { list } = await connectedListFor();

    expect(dropTargetForElements).toHaveBeenCalledWith(expect.objectContaining({ element: list }));
  });

  it('exposes its list payload through getData', async () => {
    const { list } = await connectedListFor({ type: 'sprint', id: '7' });

    expect(dropTargetOptionsFor(list)?.getData?.({ element: list, input: {} as never, source: source(null) }))
      .toEqual(expect.objectContaining({ type: 'sprint', listId: '7' }));
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

  it('does not register a drop target without acceptedTypes', async () => {
    const { list } = await connectedListFor({ acceptedTypes: null });

    expect(dropTargetForElements).not.toHaveBeenCalledWith(expect.objectContaining({ element: list }));
  });

  it('does not register a drop target with an empty acceptedTypes array', async () => {
    const { list } = await connectedListFor({ acceptedTypes: [] });

    expect(dropTargetForElements).not.toHaveBeenCalledWith(expect.objectContaining({ element: list }));
  });

  it('warns and does not register when acceptedTypes is set but type is missing or empty', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => undefined);

    const { list: listWithoutType } = await connectedListFor({ type: null, acceptedTypes: ['work_package'] });
    expect(warn).toHaveBeenCalledOnce();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('type'), expect.anything());
    expect(dropTargetForElements).not.toHaveBeenCalledWith(expect.objectContaining({ element: listWithoutType }));

    warn.mockClear();

    const { list: listWithEmptyType } = await connectedListFor({ type: '', acceptedTypes: ['work_package'] });
    expect(warn).toHaveBeenCalledOnce();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('type'), expect.anything());
    expect(dropTargetForElements).not.toHaveBeenCalledWith(expect.objectContaining({ element: listWithEmptyType }));

    warn.mockRestore();
  });

  it('rejects drops when the root outlet is not connected', async () => {
    const { list } = await connectedListFor({ outlet: false });

    expect(dropTargetOptionsFor(list)?.canDrop?.({ element: list, input: {} as never, source: source(document.createElement('div'), 'work_package') }))
      .toBe(false);
  });

  it('accepts an item of an accepted type from the same root', async () => {
    const { list, root } = await connectedListFor({ acceptedTypes: ['work_package'] });

    expect(dropTargetOptionsFor(list)?.canDrop?.({ element: list, input: {} as never, source: source(root, 'work_package') }))
      .toBe(true);
  });

  it('rejects an item type not in acceptedTypes', async () => {
    const { list, root } = await connectedListFor({ acceptedTypes: ['work_package'] });

    expect(dropTargetOptionsFor(list)?.canDrop?.({ element: list, input: {} as never, source: source(root, 'sprint') }))
      .toBe(false);
  });

  it('rejects an item from a different root', async () => {
    const { list } = await connectedListFor({ acceptedTypes: ['work_package'] });

    expect(dropTargetOptionsFor(list)?.canDrop?.({ element: list, input: {} as never, source: source(document.createElement('div'), 'work_package') }))
      .toBe(false);
  });

  it('outlines the container for a list-only drop', async () => {
    const { list } = await connectedListFor();
    const options = dropTargetOptionsFor(list);

    options?.onDragEnter?.({ location: locationOver() } as never);

    expect(list.dataset.dropContainer).toEqual('active');
  });

  it('does not outline the container while the pointer is over an item row', async () => {
    const { list } = await connectedListFor();
    const options = dropTargetOptionsFor(list);

    options?.onDrag?.({ location: locationOver({ data: sortableItemData({ itemId: '1', type: 'work_package', rootElement: null }) }) } as never);

    expect(list.dataset.dropContainer).toBeUndefined();
  });

  it('clears the container outline when the pointer moves from the list onto an item row', async () => {
    const { list } = await connectedListFor();
    const options = dropTargetOptionsFor(list);

    options?.onDragEnter?.({ location: locationOver() } as never);
    expect(list.dataset.dropContainer).toEqual('active');

    options?.onDrag?.({ location: locationOver({ data: sortableItemData({ itemId: '1', type: 'work_package', rootElement: null }) }) } as never);
    expect(list.dataset.dropContainer).toBeUndefined();
  });

  it('clears the container outline on drag leave', async () => {
    const { list } = await connectedListFor();
    const options = dropTargetOptionsFor(list);

    options?.onDragEnter?.({ location: locationOver() } as never);
    expect(list.dataset.dropContainer).toEqual('active');

    options?.onDragLeave?.({} as never);
    expect(list.dataset.dropContainer).toBeUndefined();
  });
});
