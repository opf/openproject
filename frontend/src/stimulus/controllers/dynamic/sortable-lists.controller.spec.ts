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

/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import type { autoScrollForElements as autoScrollForElementsFn } from '@atlaskit/pragmatic-drag-and-drop-auto-scroll/element';
import type { monitorForElements as monitorForElementsFn } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { waitFor } from '@testing-library/dom';
import { type Mock } from 'vitest';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type SortableListsControllerType from './sortable-lists.controller';
import type {
  sortableItemData as sortableItemDataFn,
  sortableListData as sortableListDataFn,
} from './sortable-lists/drag-and-drop';

describe('Sortable lists controller', () => {
  const flushPromises = () => new Promise<void>((resolve) => setTimeout(resolve));

  let monitorForElements:typeof monitorForElementsFn;
  let autoScrollForElements:typeof autoScrollForElementsFn;
  let SortableListsController:typeof SortableListsControllerType;
  let sortableItemData:typeof sortableItemDataFn;
  let sortableListData:typeof sortableListDataFn;

  let ctx:StimulusTestContext;
  let fixture:HTMLElement;
  let fetchMock:Mock;
  let renderStreamMessageMock:Mock;

  beforeAll(async () => {
    vi.doMock('@atlaskit/pragmatic-drag-and-drop/element/adapter', () => ({
      draggable: vi.fn(() => vi.fn()),
      dropTargetForElements: vi.fn(() => vi.fn()),
      monitorForElements: vi.fn(() => vi.fn()),
    }));

    vi.doMock('@atlaskit/pragmatic-drag-and-drop-auto-scroll/element', () => ({
      autoScrollForElements: vi.fn(() => vi.fn()),
    }));

    ({ monitorForElements } = await import('@atlaskit/pragmatic-drag-and-drop/element/adapter'));
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

  // The root spec never mounts the real list/item controllers: they are
  // covered by their own dedicated spec files. Stimulus silently ignores
  // data-controller identifiers with no registered module, so plain markup
  // carrying those attributes is enough for the DOM-contract helpers
  // (resolveSourceRow, resolveDropIntent, ...) that only look at attributes.
  function itemRow(id:string, type = 'work_package'):HTMLLIElement {
    const row = document.createElement('li');
    row.setAttribute('data-controller', 'sortable-lists--item');
    row.setAttribute('data-sortable-lists--item-id-value', id);
    row.setAttribute('data-sortable-lists--item-type-value', type);
    return row;
  }

  function renderFixture({
    moveUrlTemplates = { work_package: '/move/{id}' },
  }:{ moveUrlTemplates?:Record<string, string>|null } = {}) {
    fixture.innerHTML = `
      <div
        id="sortable-root"
        data-controller="sortable-lists"
        ${moveUrlTemplates ? `data-sortable-lists-move-url-templates-value='${JSON.stringify(moveUrlTemplates)}'` : ''}
      >
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="backlog_bucket" data-sortable-lists--list-id-value="1"></ul>
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-id-value="1"></ul>
      </div>
    `;
    const [sourceList, targetList] = Array.from(fixture.querySelectorAll<HTMLElement>('[data-controller~="sortable-lists--list"]'));
    const root = fixture.querySelector<HTMLElement>('#sortable-root')!;
    sourceList.append(itemRow('1'), itemRow('2'), itemRow('3'));
    targetList.append(itemRow('4'), itemRow('5'));
    return { root, sourceList, targetList, firstSourceItem: sourceList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="1"]')! };
  }

  function renderScrollableFixture(values = '') {
    fixture.innerHTML = `
      <div data-controller="sortable-lists" ${values}>
        <div data-sortable-lists-target="scrollable"></div>
      </div>
    `;

    return fixture.querySelector<HTMLElement>('[data-sortable-lists-target="scrollable"]')!;
  }

  async function dropCurrentItemOnList(sourceElement:HTMLElement, list:HTMLElement) {
    const monitorOptions = vi.mocked(monitorForElements).mock.lastCall?.[0];

    monitorOptions?.onDrop?.({
      source: sourcePayload(
        sourceElement,
        itemData(
          sourceElement.getAttribute('data-sortable-lists--item-id-value')!,
          sourceElement.getAttribute('data-sortable-lists--item-type-value') ?? 'work_package',
        ),
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
                type: list.getAttribute('data-sortable-lists--list-type-value')!,
                listId: list.getAttribute('data-sortable-lists--list-id-value'),
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

    await flushPromises();
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

    ctx = await setupStimulusTest({
      controllers: {
        'sortable-lists': SortableListsController,
      },
    });
    fixture = ctx.container;
  });

  afterEach(() => {
    ctx.dispose();
    vi.restoreAllMocks();
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
        id="sortable-root-1"
        data-controller="sortable-lists"
        data-sortable-lists-move-url-templates-value='{"work_package":"/move/{id}"}'
      >
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-id-value="1">
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="1" data-sortable-lists--item-type-value="work_package"></li>
        </ul>
      </div>
      <div
        id="sortable-root-2"
        data-controller="sortable-lists"
        data-sortable-lists-move-url-templates-value='{"work_package":"/move/{id}"}'
      >
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-id-value="2">
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="10" data-sortable-lists--item-type-value="work_package"></li>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="11" data-sortable-lists--item-type-value="work_package"></li>
        </ul>
      </div>
    `;

    await ctx.nextFrame();

    const firstRootMonitor = vi.mocked(monitorForElements).mock.calls[0]?.[0];
    const secondRootSource = fixture.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="10"]')!;
    const secondRootTarget = fixture.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="11"]')!;

    firstRootMonitor?.onDrop?.({
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

  it('resolves the move url from the template matching the item type', async () => {
    const { targetList, firstSourceItem } = renderFixture({
      moveUrlTemplates: { work_package: '/projects/demo/backlogs/work_packages/{id}/move' },
    });

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(fetchMock).toHaveBeenCalledWith(
      '/projects/demo/backlogs/work_packages/1/move',
      expect.objectContaining({ method: 'PUT' }),
    );
  });

  it('ignores a drop whose item type has no move url template', async () => {
    const { sourceList, targetList } = renderFixture({
      moveUrlTemplates: { work_package: '/move/{id}' },
    });
    const unknownItem = itemRow('9', 'unknown');
    sourceList.append(unknownItem);

    await ctx.nextFrame();
    await dropCurrentItemOnList(unknownItem, targetList);

    expect(fetchMock).not.toHaveBeenCalled();
    expect(itemIds(targetList)).toEqual(['4', '5']);
  });

  it('keeps the current turbo-frame query params on the resolved move url', async () => {
    fixture.innerHTML = `
      <turbo-frame
        id="backlogs-list"
        src="/projects/demo/backlogs/backlog?bucket_ids%5B%5D=1&bucket_ids%5B%5D=inbox&sprint_ids%5B%5D=2"
        data-controller="sortable-lists"
        data-sortable-lists-move-url-templates-value='{"work_package":"/projects/demo/backlogs/work_packages/{id}/move"}'
      >
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="backlog_bucket" data-sortable-lists--list-id-value="1"></ul>
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-id-value="1"></ul>
      </turbo-frame>
    `;

    const [sourceList, targetList] = Array.from(
      fixture.querySelectorAll<HTMLElement>('[data-controller~="sortable-lists--list"]'),
    );
    sourceList.append(itemRow('1'));
    targetList.append(itemRow('4'));

    await ctx.nextFrame();
    await dropCurrentItemOnList(
      sourceList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="1"]')!,
      targetList,
    );

    expect(fetchMock).toHaveBeenCalledWith(
      '/projects/demo/backlogs/work_packages/1/move?bucket_ids%5B%5D=1&bucket_ids%5B%5D=inbox&sprint_ids%5B%5D=2',
      expect.objectContaining({ method: 'PUT' }),
    );
  });

  it('only monitors drags belonging to its own root', async () => {
    const { root, firstSourceItem } = renderFixture();

    await ctx.nextFrame();

    const canMonitor = vi.mocked(monitorForElements).mock.lastCall?.[0].canMonitor;

    expect(canMonitor?.({
      source: sourcePayload(firstSourceItem, sortableItemData({ itemId: '1', type: 'work_package', rootElement: root })),
      initial: {} as never,
    })).toBe(true);
    expect(canMonitor?.({
      source: sourcePayload(firstSourceItem, sortableItemData({ itemId: '1', type: 'work_package', rootElement: document.createElement('div') })),
      initial: {} as never,
    })).toBe(false);
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
    expect(root.hasAttribute('aria-busy')).toBe(false);

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

  it('dispatches sortable-lists:moved after the move settled', async () => {
    const { root, targetList, firstSourceItem } = renderFixture();
    await ctx.nextFrame();

    const controller = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists') as unknown as { moving:boolean };
    const events:CustomEvent[] = [];
    let movingAtDispatch:boolean|undefined;
    const onMoved = (event:Event) => {
      events.push(event as CustomEvent);
      movingAtDispatch = controller.moving;
    };
    document.addEventListener('sortable-lists:moved', onMoved);

    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(events).toHaveLength(1);
    expect(events[0].detail).toEqual({ itemId: '1' });
    // ordering requirement: moving must already be false when the event fires.
    expect(movingAtDispatch).toBe(false);

    document.removeEventListener('sortable-lists:moved', onMoved);
  });

  it('does not dispatch sortable-lists:moved for a failed move', async () => {
    fetchMock.mockRejectedValueOnce(new Error('Network failure'));

    const events:CustomEvent[] = [];
    const onMoved = (event:Event) => events.push(event as CustomEvent);
    document.addEventListener('sortable-lists:moved', onMoved);

    const { targetList, firstSourceItem } = renderFixture();
    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);
    await flushPromises();

    expect(events).toHaveLength(0);

    document.removeEventListener('sortable-lists:moved', onMoved);
  });

  it('sets aria-busy on the root element only while the move request is in flight', async () => {
    let resolveMove:(response:Response) => void;

    fetchMock.mockImplementationOnce(() => {
      return new Promise<Response>((resolve) => {
        resolveMove = resolve;
      });
    });

    const { root, targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(root.getAttribute('aria-busy')).toEqual('true');

    resolveMove!(new Response('', { status: 200 }));
    await flushPromises();

    expect(root.hasAttribute('aria-busy')).toBe(false);
  });

  it('registers scrollable targets for vertical sortable list auto-scrolling', async () => {
    const scrollable = renderScrollableFixture();
    const root = fixture.querySelector<HTMLElement>('[data-controller~="sortable-lists"]')!;

    await ctx.nextFrame();

    expect(autoScrollForElements).toHaveBeenCalledWith(expect.objectContaining({
      element: scrollable,
    }));

    const options = vi.mocked(autoScrollForElements).mock.lastCall?.[0];

    expect(options?.canScroll?.({
      element: scrollable,
      input: input(),
      source: sourcePayload(itemRow('1'), sortableItemData({ itemId: '1', type: 'work_package', rootElement: root })),
    })).toBe(true);
    expect(options?.canScroll?.({
      element: scrollable,
      input: input(),
      source: sourcePayload(document.createElement('div'), { type: 'unrelated' }),
    })).toBe(false);
    expect(options?.canScroll?.({
      element: scrollable,
      input: input(),
      source: sourcePayload(itemRow('1'), sortableItemData({ itemId: '1', type: 'work_package', rootElement: document.createElement('div') })),
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
