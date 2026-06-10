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

/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-return */

import type { autoScrollForElements as autoScrollForElementsFn } from '@atlaskit/pragmatic-drag-and-drop-auto-scroll/element';
import type { dropTargetForElements as dropTargetForElementsFn, monitorForElements as monitorForElementsFn } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { waitFor } from '@testing-library/dom';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type SortableListsControllerType from './sortable-lists.controller';
import type {
  sortableItemData as sortableItemDataFn,
  sortableListData as sortableListDataFn,
} from './sortable-lists/drag-and-drop';

describe('Sortable lists controller', () => {
  const flushPromises = () => new Promise<void>((resolve) => setTimeout(resolve));

  let dropTargetForElements:typeof dropTargetForElementsFn;
  let monitorForElements:typeof monitorForElementsFn;
  let autoScrollForElements:typeof autoScrollForElementsFn;
  let SortableListsController:typeof SortableListsControllerType;
  let sortableItemData:typeof sortableItemDataFn;
  let sortableListData:typeof sortableListDataFn;

  let ctx:StimulusTestContext;
  let fixture:HTMLElement;
  let fetchMock:ReturnType<typeof vi.fn>;
  let loadingIndicator:HTMLElement;
  let renderStreamMessageMock:ReturnType<typeof vi.fn>;

  beforeAll(async () => {
    vi.doMock('@atlaskit/pragmatic-drag-and-drop/element/adapter', () => ({
      draggable: vi.fn(() => vi.fn()),
      dropTargetForElements: vi.fn(() => vi.fn()),
      monitorForElements: vi.fn(() => vi.fn()),
    }));

    vi.doMock('@atlaskit/pragmatic-drag-and-drop-auto-scroll/element', () => ({
      autoScrollForElements: vi.fn(() => vi.fn()),
    }));

    ({ dropTargetForElements, monitorForElements } = await import('@atlaskit/pragmatic-drag-and-drop/element/adapter'));
    ({ autoScrollForElements } = await import('@atlaskit/pragmatic-drag-and-drop-auto-scroll/element'));
    ({ default: SortableListsController } = await import('./sortable-lists.controller'));
    ({ sortableItemData, sortableListData } = await import('./sortable-lists/drag-and-drop'));
  });

  function input() {
    return {
      altKey: false,
      button: 0,
      buttons: 0,
      ctrlKey: false,
      metaKey: false,
      shiftKey: false,
      clientX: 10,
      clientY: 10,
      pageX: 10,
      pageY: 10,
    };
  }

  function itemRow(id:string):HTMLLIElement {
    const row = document.createElement('li');

    row.setAttribute('data-sortable-lists--item-id-value', id);
    row.setAttribute('data-sortable-lists--item-type-value', 'work_package');

    return row;
  }

  function renderFixture({
    acceptedType = null,
    moveUrlTemplate = '/move/{id}',
  }:{
    acceptedType?:string|null;
    moveUrlTemplate?:string|null;
  } = {}) {
    fixture.innerHTML = `
      <div
        data-controller="sortable-lists"
        ${acceptedType ? `data-sortable-lists-accepted-type-value="${acceptedType}"` : ''}
        ${moveUrlTemplate ? `data-sortable-lists-move-url-template-value="${moveUrlTemplate}"` : ''}
      >
        <ul data-sortable-lists-target="list" data-sortable-lists-list-type="backlog_bucket" data-sortable-lists-list-id="1"></ul>
        <ul data-sortable-lists-target="list" data-sortable-lists-list-type="sprint" data-sortable-lists-list-id="1"></ul>
      </div>
    `;

    const [sourceList, targetList] = Array.from(fixture.querySelectorAll<HTMLElement>('[data-sortable-lists-target="list"]'));
    const root = fixture.querySelector<HTMLElement>('[data-controller="sortable-lists"]')!;

    sourceList.append(itemRow('1'), itemRow('2'), itemRow('3'));
    targetList.append(itemRow('4'), itemRow('5'));

    return {
      root,
      sourceList,
      targetList,
      firstSourceItem: sourceList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="1"]')!,
    };
  }

  function renderScrollableFixture(values = '') {
    fixture.innerHTML = `
      <div data-controller="sortable-lists" ${values}>
        <div data-sortable-lists-target="scrollable"></div>
      </div>
    `;

    return fixture.querySelector<HTMLElement>('[data-sortable-lists-target="scrollable"]')!;
  }

  function renderInvalidListFixture() {
    fixture.innerHTML = `
      <div data-controller="sortable-lists">
        <ul data-sortable-lists-target="list"></ul>
      </div>
    `;

    return fixture.querySelector<HTMLElement>('[data-sortable-lists-target="list"]')!;
  }

  async function dropCurrentItemOnList(sourceElement:HTMLElement, list:HTMLElement) {
    const monitorOptions = vi.mocked(monitorForElements).mock.lastCall?.[0];

    await monitorOptions?.onDrop?.({
      source: sourcePayload(
        sourceElement,
        itemData(sourceElement.getAttribute('data-sortable-lists--item-id-value')!),
      ),
      location: {
        initial: {
          dropTargets: [],
          input: input(),
        },
        current: {
          dropTargets: [
            dropTargetRecord(
              list,
              sortableListData({
                type: list.getAttribute('data-sortable-lists-list-type')!,
                listId: list.getAttribute('data-sortable-lists-list-id'),
              }),
            ),
          ],
          input: input(),
        },
        previous: {
          dropTargets: [],
        },
      },
    });
  }

  function itemData(itemId = '1', type = 'work_package') {
    return sortableItemData({ itemId, type });
  }

  function sourcePayload(element:HTMLElement, data:Record<string|symbol, unknown> = itemData()) {
    return {
      data,
      dragHandle: null,
      element,
    };
  }

  function dropTargetRecord(element:HTMLElement, data:Record<string|symbol, unknown>) {
    return {
      data,
      dropEffect: 'move' as const,
      element,
      isActiveDueToStickiness: false,
    };
  }

  function dropTargetOptionsFor(element:HTMLElement) {
    return vi.mocked(dropTargetForElements).mock.calls.find(([options]) => options.element === element)?.[0];
  }

  function itemIds(list:HTMLElement):string[] {
    return Array.from(list.querySelectorAll('[data-sortable-lists--item-id-value]'))
      .map((element) => element.getAttribute('data-sortable-lists--item-id-value')!);
  }

  beforeEach(async () => {
    vi.clearAllMocks();

    fetchMock = vi.fn(() => Promise.resolve(new Response('', { status: 200 })));
    renderStreamMessageMock = vi.fn(() => Promise.resolve());
    vi.stubGlobal('fetch', fetchMock);
    vi.stubGlobal('Turbo', {
      fetch: fetchMock,
      renderStreamMessage: renderStreamMessageMock,
    });

    loadingIndicator = document.createElement('div');
    loadingIndicator.id = 'global-loading-indicator';
    loadingIndicator.hidden = true;
    document.body.appendChild(loadingIndicator);

    ctx = await setupStimulusTest({
      controllers: {
        'sortable-lists': SortableListsController,
      },
    });
    fixture = ctx.container;
  });

  afterEach(() => {
    ctx.dispose();
    loadingIndicator.remove();
    vi.unstubAllGlobals();
  });

  it('does not turn a list-only drop onto the source list into an append move', async () => {
    const { sourceList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, sourceList);

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('ignores drops that belong to another sortable lists root', async () => {
    fixture.innerHTML = `
      <div
        data-controller="sortable-lists"
        data-sortable-lists-accepted-type-value="work_package"
        data-sortable-lists-move-url-template-value="/move/{id}"
      >
        <ul data-sortable-lists-target="list" data-sortable-lists-list-type="sprint" data-sortable-lists-list-id="1">
          <li data-sortable-lists--item-id-value="1" data-sortable-lists--item-type-value="work_package"></li>
        </ul>
      </div>
      <div
        data-controller="sortable-lists"
        data-sortable-lists-accepted-type-value="work_package"
        data-sortable-lists-move-url-template-value="/move/{id}"
      >
        <ul data-sortable-lists-target="list" data-sortable-lists-list-type="sprint" data-sortable-lists-list-id="2">
          <li data-sortable-lists--item-id-value="10" data-sortable-lists--item-type-value="work_package"></li>
          <li data-sortable-lists--item-id-value="11" data-sortable-lists--item-type-value="work_package"></li>
        </ul>
      </div>
    `;

    await ctx.nextFrame();

    const firstRootMonitor = vi.mocked(monitorForElements).mock.calls[0]?.[0];
    const secondRootSource = fixture.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="10"]')!;
    const secondRootTarget = fixture.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="11"]')!;

    await firstRootMonitor?.onDrop?.({
      source: sourcePayload(secondRootSource, itemData('10', 'work_package')),
      location: {
        initial: {
          dropTargets: [],
          input: input(),
        },
        current: {
          dropTargets: [
            dropTargetRecord(secondRootTarget, itemData('11', 'work_package')),
          ],
          input: input(),
        },
        previous: {
          dropTargets: [],
        },
      },
    });

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('ignores drops whose source type does not match the root accepted type', async () => {
    const { targetList, firstSourceItem } = renderFixture({ acceptedType: 'work_package' });
    const targetItem = targetList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="4"]')!;

    await ctx.nextFrame();

    await vi.mocked(monitorForElements).mock.lastCall?.[0].onDrop?.({
      source: sourcePayload(firstSourceItem, itemData('1', 'meeting_agenda_item')),
      location: {
        initial: {
          dropTargets: [],
          input: input(),
        },
        current: {
          dropTargets: [
            dropTargetRecord(targetItem, itemData('4', 'work_package')),
          ],
          input: input(),
        },
        previous: {
          dropTargets: [],
        },
      },
    });

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('appends the item when list-only dropping onto another list', async () => {
    const { targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(fetchMock).toHaveBeenCalledOnce();

    const options = fetchMock.mock.lastCall?.[1] as { body:FormData };

    expect(options.body.get('list_type')).toEqual('sprint');
    expect(options.body.get('list_id')).toEqual('1');
    expect(options.body.get('prev_id')).toEqual('5');
  });

  it('builds the move URL from the controller URI template', async () => {
    const { targetList, firstSourceItem } = renderFixture({
      moveUrlTemplate: '/projects/demo/backlogs/work_packages/{id}/move',
    });

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(fetchMock).toHaveBeenCalledWith(
      '/projects/demo/backlogs/work_packages/1/move',
      expect.objectContaining({ method: 'PUT' }),
    );
  });

  it('does nothing when the controller has no move URL template', async () => {
    const { targetList, firstSourceItem } = renderFixture({ moveUrlTemplate: null });

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('marks the sortable lists root and global loading indicator while moving an item', async () => {
    let resolveMove:(response:Response) => void;

    fetchMock.mockImplementationOnce(() => {
      return new Promise<Response>((resolve) => {
        resolveMove = resolve;
      });
    });

    const { root, targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(root.dataset.sortableListsMoving).toEqual('true');
    expect(root.getAttribute('aria-busy')).toEqual('true');
    expect(loadingIndicator.hidden).toBe(false);

    resolveMove!(new Response('', { status: 200 }));
    await flushPromises();

    expect(root.hasAttribute('data-sortable-lists-moving')).toBe(false);
    expect(root.hasAttribute('aria-busy')).toBe(false);
    expect(loadingIndicator.hidden).toBe(true);
  });

  it('rejects new sortable-list drags and drops while a move is pending', async () => {
    let resolveMove:(response:Response) => void;

    fetchMock.mockImplementationOnce(() => {
      return new Promise<Response>((resolve) => {
        resolveMove = resolve;
      });
    });

    const { targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(vi.mocked(monitorForElements).mock.lastCall?.[0].canMonitor?.({
      source: sourcePayload(firstSourceItem),
      initial: {} as never,
    })).toBe(false);
    expect(dropTargetOptionsFor(targetList)?.canDrop?.({
      element: targetList,
      input: input(),
      source: sourcePayload(firstSourceItem),
    })).toBe(false);

    resolveMove!(new Response('', { status: 200 }));
    await flushPromises();
  });

  it('dispatches an error toast when the move request rejects', async () => {
    const toastEvents:CustomEvent[] = [];
    const onToast = (event:Event) => toastEvents.push(event as CustomEvent);

    window.addEventListener('op:toasters:add', onToast);
    fetchMock.mockRejectedValueOnce(new Error('Network failure'));

    const { root, targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);
    await flushPromises();

    expect(toastEvents).toHaveLength(1);
    expect(toastEvents[0].detail).toEqual(expect.objectContaining({
      message: expect.any(String),
      type: 'error',
    }));
    expect(root.hasAttribute('data-sortable-lists-moving')).toBe(false);
    expect(loadingIndicator.hidden).toBe(true);

    window.removeEventListener('op:toasters:add', onToast);
  });

  it('moves the dropped row into the target list before the move request resolves', async () => {
    let resolveMove:(response:Response) => void;

    fetchMock.mockImplementationOnce(() => {
      return new Promise<Response>((resolve) => {
        resolveMove = resolve;
      });
    });

    const { sourceList, targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    // The row is appended optimistically while the request is still pending.
    expect(itemIds(targetList)).toEqual(['4', '5', '1']);
    expect(itemIds(sourceList)).toEqual(['2', '3']);

    resolveMove!(new Response('', { status: 200 }));
    await flushPromises();

    expect(itemIds(targetList)).toEqual(['4', '5', '1']);
  });

  it('rolls the dropped row back to its original position when the move request fails', async () => {
    fetchMock.mockRejectedValueOnce(new Error('Network failure'));

    const { sourceList, targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);
    await flushPromises();

    expect(itemIds(sourceList)).toEqual(['1', '2', '3']);
    expect(itemIds(targetList)).toEqual(['4', '5']);
  });

  it('does not dispatch a generic toast when a 422 turbo stream rejects the move', async () => {
    const toastEvents:CustomEvent[] = [];
    const onToast = (event:Event) => toastEvents.push(event as CustomEvent);

    window.addEventListener('op:toasters:add', onToast);
    fetchMock.mockResolvedValueOnce(new Response('', {
      headers: { 'Content-Type': 'text/vnd.turbo-stream.html' },
      status: 422,
    }));

    const { sourceList, targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);
    await flushPromises();

    await waitFor(() => {
      expect(itemIds(sourceList)).toEqual(['1', '2', '3']);
      expect(itemIds(targetList)).toEqual(['4', '5']);
      expect(renderStreamMessageMock).toHaveBeenCalledOnce();
    });
    expect(toastEvents).toHaveLength(0);

    window.removeEventListener('op:toasters:add', onToast);
  });

  it('dispatches a generic toast when a non-422 response rejects the move', async () => {
    const toastEvents:CustomEvent[] = [];
    const onToast = (event:Event) => toastEvents.push(event as CustomEvent);

    window.addEventListener('op:toasters:add', onToast);
    fetchMock.mockResolvedValueOnce(new Response('', { status: 500 }));

    const { sourceList, targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);
    await flushPromises();

    expect(itemIds(sourceList)).toEqual(['1', '2', '3']);
    expect(itemIds(targetList)).toEqual(['4', '5']);
    expect(toastEvents).toHaveLength(1);

    window.removeEventListener('op:toasters:add', onToast);
  });

  it('registers Backlogs lists as drop targets', async () => {
    const { sourceList, targetList } = renderFixture();

    await ctx.nextFrame();

    expect(dropTargetForElements).toHaveBeenCalledWith(expect.objectContaining({
      element: sourceList,
    }));
    expect(dropTargetForElements).toHaveBeenCalledWith(expect.objectContaining({
      element: targetList,
    }));
  });

  it('does not register list targets without sortable list data', async () => {
    const list = renderInvalidListFixture();

    await ctx.nextFrame();

    expect(dropTargetForElements).not.toHaveBeenCalledWith(expect.objectContaining({
      element: list,
    }));
  });

  it('accepts item drops when the source type matches the root accepted type', async () => {
    const { targetList, firstSourceItem } = renderFixture({ acceptedType: 'work_package' });

    await ctx.nextFrame();

    expect(dropTargetOptionsFor(targetList)?.canDrop?.({
      element: targetList,
      input: input(),
      source: sourcePayload(firstSourceItem, itemData('1', 'work_package')),
    })).toBe(true);
  });

  it('applies the accepted item type to every list target in the controller root', async () => {
    const { sourceList, targetList, firstSourceItem } = renderFixture({ acceptedType: 'work_package' });

    await ctx.nextFrame();

    for (const list of [sourceList, targetList]) {
      expect(dropTargetOptionsFor(list)?.canDrop?.({
        element: list,
        input: input(),
        source: sourcePayload(firstSourceItem, itemData('1', 'meeting_agenda_item')),
      })).toBe(false);
    }
  });

  it('rejects item drops when the source type does not match the root accepted type', async () => {
    const { targetList, firstSourceItem } = renderFixture({ acceptedType: 'work_package' });

    await ctx.nextFrame();

    expect(dropTargetOptionsFor(targetList)?.canDrop?.({
      element: targetList,
      input: input(),
      source: sourcePayload(firstSourceItem, itemData('1', 'meeting_agenda_item')),
    })).toBe(false);
  });

  it('registers scrollable targets for vertical sortable list auto-scrolling', async () => {
    const scrollable = renderScrollableFixture();

    await ctx.nextFrame();

    expect(autoScrollForElements).toHaveBeenCalledWith(expect.objectContaining({
      element: scrollable,
    }));

    const options = vi.mocked(autoScrollForElements).mock.lastCall?.[0];

    expect(options?.canScroll?.({
      element: scrollable,
      input: input(),
      source: sourcePayload(itemRow('1')),
    })).toBe(true);
    expect(options?.canScroll?.({
      element: scrollable,
      input: input(),
      source: sourcePayload(document.createElement('div'), { type: 'unrelated' }),
    })).toBe(false);
    expect(options?.getAllowedAxis?.({
      element: scrollable,
      input: input(),
      source: sourcePayload(itemRow('1')),
    })).toEqual('vertical');
    expect(options?.getConfiguration?.({
      element: scrollable,
      input: input(),
      source: sourcePayload(itemRow('1')),
    })).toEqual({ maxScrollSpeed: 'standard' });
  });

  it('cleans up scrollable target auto-scrolling on disconnect', async () => {
    const scrollableCleanup = vi.fn();
    vi.mocked(autoScrollForElements).mockReturnValue(scrollableCleanup);

    renderScrollableFixture();

    await ctx.nextFrame();

    fixture.innerHTML = '';
    await ctx.nextFrame();

    expect(scrollableCleanup).toHaveBeenCalledOnce();
  });
});
