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

// vi.doMock is not hoisted above imports, unlike vi.mock, so the subject
// below is imported dynamically further down, after these calls run.
vi.doMock('@atlaskit/pragmatic-drag-and-drop/element/adapter', () => ({
  draggable: vi.fn(() => vi.fn()),
  dropTargetForElements: vi.fn(() => vi.fn()),
  monitorForElements: vi.fn(() => vi.fn()),
}));

vi.doMock('@atlaskit/pragmatic-drag-and-drop-auto-scroll/element', () => ({
  autoScrollForElements: vi.fn(() => vi.fn()),
}));

// This spec mounts the real item controller, which pulls in these three
// modules. Stub them so its Pragmatic side effects stay inert; nothing
// here reads them back.
vi.doMock('@atlaskit/pragmatic-drag-and-drop/combine', () => ({
  combine: vi.fn((...cleanups:(() => void)[]) => vi.fn(() => {
    cleanups.forEach((cleanup) => cleanup());
  })),
}));

vi.doMock('@atlaskit/pragmatic-drag-and-drop/prevent-unhandled', () => ({
  preventUnhandled: { start: vi.fn(), stop: vi.fn() },
}));

vi.doMock('@atlaskit/pragmatic-drag-and-drop/element/set-custom-native-drag-preview', () => ({
  setCustomNativeDragPreview: vi.fn(),
}));

import type { monitorForElements as monitorForElementsFn } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { waitFor } from '@testing-library/dom';
import { type Mock, type MockInstance } from 'vitest';
import { LiveRegionElement } from '@primer/live-region-element';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type SortableListsControllerType from './sortable-lists.controller';
import type {
  sortableItemData as sortableItemDataFn,
  sortableListData as sortableListDataFn,
} from './sortable-lists/drag-and-drop';

describe('Sortable lists controller', () => {
  const flushPromises = () => new Promise<void>((resolve) => setTimeout(resolve));

  let monitorForElements:typeof monitorForElementsFn;
  let SortableListsController:typeof SortableListsControllerType;
  let sortableItemData:typeof sortableItemDataFn;
  let sortableListData:typeof sortableListDataFn;

  let ctx:StimulusTestContext;
  let fixture:HTMLElement;
  let fetchMock:Mock;
  let renderStreamMessageMock:Mock;
  // `ReturnType<typeof vi.spyOn>` collapses to a call signature TypeScript
  // cannot resolve `.mock.calls`'s element type from; pin the spied method's
  // own signature instead so calls stay typed.
  let announceSpy:MockInstance<typeof LiveRegionElement.prototype.announce>;

  beforeAll(async () => {
    ({ monitorForElements } = await import('@atlaskit/pragmatic-drag-and-drop/element/adapter'));
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
    row.setAttribute('data-controller', 'sortable-lists--item');
    row.setAttribute('data-sortable-lists--item-id-value', id);
    row.setAttribute('data-sortable-lists--item-type-value', 'work_package');
    row.setAttribute('data-sortable-lists--item-label-value', `Story ${id}`);
    return row;
  }

  function announcedMessages():[string, unknown][] {
    return announceSpy.mock.calls.map((call) => [call[0], call[1]]);
  }

  function renderFixture({
    moveUrlTemplate = '/move/{id}',
    optimistic = false,
  }:{ moveUrlTemplate?:string|null; optimistic?:boolean } = {}) {
    fixture.innerHTML = `
      <div
        id="sortable-root"
        data-controller="sortable-lists"
        ${moveUrlTemplate ? `data-sortable-lists-move-url-template-value="${moveUrlTemplate}"` : ''}
        ${optimistic ? 'data-sortable-lists-optimistic-value="true"' : ''}
        data-sortable-lists-sortable-lists--list-outlet="#sortable-root [data-controller~='sortable-lists--list']"
        data-sortable-lists-sortable-lists--item-outlet="#sortable-root [data-controller~='sortable-lists--item']"
        data-sortable-lists-sortable-lists--scrollable-outlet="#sortable-root [data-controller~='sortable-lists--scrollable']"
      >
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="backlog_bucket" data-sortable-lists--list-id-value="1" data-sortable-lists--list-accepted-type-value="work_package" data-sortable-lists--list-name-value="Product backlog"></ul>
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-id-value="1" data-sortable-lists--list-accepted-type-value="work_package" data-sortable-lists--list-name-value="Sprint 1"></ul>
        <div data-controller="sortable-lists--scrollable"></div>
      </div>
    `;
    const [sourceList, targetList] = Array.from(fixture.querySelectorAll<HTMLElement>('[data-controller~="sortable-lists--list"]'));
    const root = fixture.querySelector<HTMLElement>('#sortable-root')!;
    const scrollable = fixture.querySelector<HTMLElement>('[data-controller~="sortable-lists--scrollable"]')!;
    sourceList.append(itemRow('1'), itemRow('2'), itemRow('3'));
    targetList.append(itemRow('4'), itemRow('5'));
    return {
      root, sourceList, targetList, scrollable, firstSourceItem: sourceList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="1"]')!,
    };
  }

  async function dropCurrentItemOnList(sourceElement:HTMLElement, list:HTMLElement, type = 'work_package') {
    const monitorOptions = vi.mocked(monitorForElements).mock.lastCall?.[0];

    monitorOptions?.onDrop?.({
      source: sourcePayload(
        sourceElement,
        itemData(sourceElement.getAttribute('data-sortable-lists--item-id-value')!, type),
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
                name: list.getAttribute('data-sortable-lists--list-name-value'),
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

  // Direct-child ids only: a section row can itself host a nested list of its
  // own items, and querySelectorAll (used by itemIds above) would pick those
  // up too, muddying assertions about the outer list's own row order.
  function directItemIds(container:HTMLElement):(string|null)[] {
    return Array.from(container.children).map((child) => child.getAttribute('data-sortable-lists--item-id-value'));
  }

  function fieldRow(id:string):HTMLLIElement {
    const row = document.createElement('li');
    row.setAttribute('data-controller', 'sortable-lists--item');
    row.setAttribute('data-sortable-lists--item-id-value', id);
    row.setAttribute('data-sortable-lists--item-type-value', 'custom_field');
    row.setAttribute('data-sortable-lists--item-label-value', `Field ${id}`);
    return row;
  }

  function sectionRow(id:string):HTMLLIElement {
    const row = document.createElement('li');
    row.setAttribute('data-controller', 'sortable-lists--item');
    row.setAttribute('data-sortable-lists--item-id-value', id);
    row.setAttribute('data-sortable-lists--item-type-value', 'section');
    row.setAttribute('data-sortable-lists--item-label-value', `Section ${id}`);
    return row;
  }

  // A root serving two item types (sections and custom fields) with distinct
  // move endpoints, each type's items living in their own list.
  function renderTypeMapFixture({
    moveUrlTemplates = '{"section":"/sections/{id}/drop","custom_field":"/fields/{id}/drop"}',
    moveUrlTemplate,
  }:{ moveUrlTemplates?:string|null; moveUrlTemplate?:string } = {}) {
    fixture.innerHTML = `
      <div
        id="sortable-root"
        data-controller="sortable-lists"
        ${moveUrlTemplates ? `data-sortable-lists-move-url-templates-value='${moveUrlTemplates}'` : ''}
        ${moveUrlTemplate ? `data-sortable-lists-move-url-template-value="${moveUrlTemplate}"` : ''}
        data-sortable-lists-sortable-lists--list-outlet="#sortable-root [data-controller~='sortable-lists--list']"
        data-sortable-lists-sortable-lists--item-outlet="#sortable-root [data-controller~='sortable-lists--item']"
      >
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="custom_field" data-sortable-lists--list-id-value="1" data-sortable-lists--list-accepted-type-value="custom_field" data-sortable-lists--list-name-value="Fields"></ul>
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="section" data-sortable-lists--list-id-value="1" data-sortable-lists--list-accepted-type-value="section" data-sortable-lists--list-name-value="Sections"></ul>
      </div>
    `;
    const root = fixture.querySelector<HTMLElement>('#sortable-root')!;
    const fieldList = fixture.querySelector<HTMLElement>('[data-sortable-lists--list-type-value="custom_field"]')!;
    const sectionList = fixture.querySelector<HTMLElement>('[data-sortable-lists--list-type-value="section"]')!;

    return { root, fieldList, sectionList };
  }

  // A nested dual-role topology: the outer list's rows are section items
  // (a <div>, not an <li>, hosting their own inner list of custom_field
  // items). Sections and fields share one root, so a section item is
  // contained by both the outer list (directly) and, for fields, by the
  // outer list transitively through the section row.
  function renderNestedFixture() {
    fixture.innerHTML = `
      <div
        id="sortable-root"
        data-controller="sortable-lists"
        data-sortable-lists-move-url-template-value="/move/{id}"
        data-sortable-lists-sortable-lists--list-outlet="#sortable-root [data-controller~='sortable-lists--list']"
        data-sortable-lists-sortable-lists--item-outlet="#sortable-root [data-controller~='sortable-lists--item']"
      >
        <ul
          data-controller="sortable-lists--list"
          data-sortable-lists--list-type-value="section"
          data-sortable-lists--list-id-value="1"
          data-sortable-lists--list-accepted-type-value="section"
          data-sortable-lists--list-name-value="Sections"
        >
          <div
            data-controller="sortable-lists--item"
            data-sortable-lists--item-id-value="s1"
            data-sortable-lists--item-type-value="section"
            data-sortable-lists--item-label-value="Section 1"
          >
            <ul
              data-controller="sortable-lists--list"
              data-sortable-lists--list-type-value="custom_field"
              data-sortable-lists--list-id-value="s1"
              data-sortable-lists--list-accepted-type-value="custom_field"
              data-sortable-lists--list-name-value="Fields"
            ></ul>
          </div>
          <div
            data-controller="sortable-lists--item"
            data-sortable-lists--item-id-value="s2"
            data-sortable-lists--item-type-value="section"
            data-sortable-lists--item-label-value="Section 2"
          ></div>
        </ul>
      </div>
    `;
    const root = fixture.querySelector<HTMLElement>('#sortable-root')!;
    const sectionList = fixture.querySelector<HTMLElement>('[data-sortable-lists--list-type-value="section"]')!;
    const sectionItem = fixture.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="s1"]')!;
    const fieldList = fixture.querySelector<HTMLElement>('[data-sortable-lists--list-type-value="custom_field"]')!;
    fieldList.append(fieldRow('cf1'), fieldRow('cf2'));

    return {
      root,
      sectionList,
      sectionItem,
      fieldList,
      firstFieldItem: fieldList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="cf1"]')!,
    };
  }

  beforeEach(async () => {
    vi.clearAllMocks();

    // The synthetic drop input below carries fixed coordinates that bear no
    // relation to where the fixture's rows actually lay out, so a real
    // hit-test would report the source's own row for every drop and the
    // "released over the source row" guard would swallow them all. Report
    // nothing under the pointer by default; the tests that exercise that
    // guard mock their own element stack.
    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([]);

    fetchMock = vi.fn(() => Promise.resolve(new Response('', { status: 200 })));
    renderStreamMessageMock = vi.fn(() => Promise.resolve());
    vi.stubGlobal('fetch', fetchMock);
    vi.stubGlobal('Turbo', {
      fetch: fetchMock,
      renderStreamMessage: renderStreamMessageMock,
    });

    document.body.appendChild(document.createElement('live-region'));
    announceSpy = vi.spyOn(LiveRegionElement.prototype, 'announce');
    // I18n.store merges straight into I18n#translations, which the lookup
    // reads through the active locale ("en" by default); an unlocalized
    // payload here would resolve to nothing and every message would report
    // as missing.
    window.I18n.store({
      en: {
        js: {
          sortable_lists: {
            announcements: {
              fallback_item_label: 'Item',
              fallback_list_name: 'another list',
              move_failed_check_position: 'Move failed. Check the item\'s current position.',
              move_failed_rolled_back: 'Move failed. %{label} returned to its previous position.',
              moved: '%{label} moved to position %{position} of %{total}',
              moved_to_list: '%{label} moved to %{list}, position %{position} of %{total}',
            },
          },
        },
      },
    });

    ctx = await setupStimulusTest({
      controllers: {
        'sortable-lists': SortableListsController,
        'sortable-lists--list': (await import('./sortable-lists/list.controller')).default,
        'sortable-lists--item': (await import('./sortable-lists/item.controller')).default,
        'sortable-lists--scrollable': (await import('./sortable-lists/scrollable.controller')).default,
      },
    });
    fixture = ctx.container;
  });

  afterEach(() => {
    ctx.dispose();
    document.body.querySelector('live-region')?.remove();
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it('moves a list-only drop onto the source list to its configured position', async () => {
    const { sourceList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, sourceList);

    expect(itemIds(sourceList)).toEqual(['2', '3', '1']);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('skips the move request when a drop lands at the source item current position', async () => {
    const { sourceList } = renderFixture();
    const lastSourceItem = sourceList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="3"]')!;

    await ctx.nextFrame();
    await dropCurrentItemOnList(lastSourceItem, sourceList);

    expect(itemIds(sourceList)).toEqual(['1', '2', '3']);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('ignores a list-only drop released over the source row itself', async () => {
    const { sourceList } = renderFixture();
    // A middle item: neither list boundary the configured drop position
    // would resolve to, so a real (wrong) move would be observable if the
    // guard that ignores a drop still over the source's own row failed to
    // short-circuit it.
    const middleSourceItem = sourceList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="2"]')!;

    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([middleSourceItem]);

    await ctx.nextFrame();
    await dropCurrentItemOnList(middleSourceItem, sourceList);

    expect(itemIds(sourceList)).toEqual(['1', '2', '3']);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('still appends the first item dropped over its own list background', async () => {
    const { sourceList, firstSourceItem } = renderFixture();
    // Releasing the first row over the list's empty space below the last
    // row hit-tests to the rows container, not an item row. Descending
    // into the container would resolve its first item -- the dragged row
    // itself -- and wrongly swallow a genuine send-to-bottom as a drop
    // back onto the source row.
    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([sourceList]);

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, sourceList);

    expect(itemIds(sourceList)).toEqual(['2', '3', '1']);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('sees past Pragmatic\'s honey-pot overlay to the source row underneath it', async () => {
    const { sourceList } = renderFixture();
    // A native drag can leave Pragmatic's own tracking overlay as the
    // topmost element at the pointer; a raw hit-test that trusts it as-is
    // would miss the source row underneath and wrongly move the item.
    const middleSourceItem = sourceList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="2"]')!;
    const honeyPot = document.createElement('div');
    honeyPot.setAttribute('data-pdnd-honey-pot', 'true');

    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([honeyPot, middleSourceItem]);

    await ctx.nextFrame();
    await dropCurrentItemOnList(middleSourceItem, sourceList);

    expect(itemIds(sourceList)).toEqual(['1', '2', '3']);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('moves a work package into an empty list despite its blankslate placeholder', async () => {
    const { targetList, firstSourceItem } = renderFixture();
    targetList.innerHTML = '';
    const blankslate = document.createElement('li');
    blankslate.setAttribute('data-empty-list-item', 'true');
    targetList.append(blankslate);
    // The element under the pointer at drop is the blankslate placeholder,
    // not an item -- this must not be confused with dropping back onto the
    // source's own row.
    vi.spyOn(document, 'elementsFromPoint').mockReturnValue([blankslate]);

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(itemIds(targetList)).toEqual(['1']);
    expect(fetchMock).toHaveBeenCalledOnce();
  });

  it('ignores drops that belong to another sortable lists root', async () => {
    fixture.innerHTML = `
      <div
        id="sortable-root-1"
        data-controller="sortable-lists"
        data-sortable-lists-move-url-template-value="/move/{id}"
        data-sortable-lists-sortable-lists--list-outlet="#sortable-root-1 [data-controller~='sortable-lists--list']"
        data-sortable-lists-sortable-lists--item-outlet="#sortable-root-1 [data-controller~='sortable-lists--item']"
      >
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-id-value="1" data-sortable-lists--list-accepted-type-value="work_package">
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="1" data-sortable-lists--item-type-value="work_package"></li>
        </ul>
      </div>
      <div
        id="sortable-root-2"
        data-controller="sortable-lists"
        data-sortable-lists-move-url-template-value="/move/{id}"
        data-sortable-lists-sortable-lists--list-outlet="#sortable-root-2 [data-controller~='sortable-lists--list']"
        data-sortable-lists-sortable-lists--item-outlet="#sortable-root-2 [data-controller~='sortable-lists--item']"
      >
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-id-value="2" data-sortable-lists--list-accepted-type-value="work_package">
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

  it('builds the move URL from the controller URI template', async () => {
    const { targetList, firstSourceItem } = renderFixture({
      moveUrlTemplate: '/projects/demo/backlogs/work_packages/{id}/move',
      optimistic: true,
    });

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(fetchMock).toHaveBeenCalledWith(
      '/projects/demo/backlogs/work_packages/1/move?optimistic=true',
      expect.objectContaining({ method: 'PUT' }),
    );
  });

  it('flags the move request as optimistic', async () => {
    const { targetList, firstSourceItem } = renderFixture({
      moveUrlTemplate: '/projects/demo/backlogs/work_packages/{id}/move',
      optimistic: true,
    });

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    const calledUrl = fetchMock.mock.lastCall?.[0] as string;
    expect(new URL(calledUrl, 'http://localhost').searchParams.get('optimistic')).toBe('true');
  });

  it('omits the optimistic flag by default', async () => {
    const { targetList, firstSourceItem } = renderFixture({
      moveUrlTemplate: '/projects/demo/backlogs/work_packages/{id}/move',
    });

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    const calledUrl = fetchMock.mock.lastCall?.[0] as string;
    expect(new URL(calledUrl, 'http://localhost').searchParams.has('optimistic')).toBe(false);
  });

  it('appends optimistic=true when the root opts in', async () => {
    const { targetList, firstSourceItem } = renderFixture({
      moveUrlTemplate: '/projects/demo/backlogs/work_packages/{id}/move',
      optimistic: true,
    });

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    const calledUrl = fetchMock.mock.lastCall?.[0] as string;
    expect(new URL(calledUrl, 'http://localhost').searchParams.get('optimistic')).toBe('true');
  });

  it('ignores the turbo frame query when building the move URL', async () => {
    // The move endpoint does not read filter params, and the active filter is
    // preserved by the frame reloading its own src. The move URL therefore
    // carries no frame params, even when the frame has a filtered src.
    fixture.innerHTML = `
      <turbo-frame
        id="backlogs-list"
        src="/projects/demo/backlogs/backlog?bucket_ids%5B%5D=1&bucket_ids%5B%5D=inbox&sprint_ids%5B%5D=2"
        data-controller="sortable-lists"
        data-sortable-lists-move-url-template-value="/projects/demo/backlogs/work_packages/{id}/move"
        data-sortable-lists-optimistic-value="true"
        data-sortable-lists-sortable-lists--list-outlet="#backlogs-list [data-controller~='sortable-lists--list']"
        data-sortable-lists-sortable-lists--item-outlet="#backlogs-list [data-controller~='sortable-lists--item']"
      >
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="backlog_bucket" data-sortable-lists--list-id-value="1" data-sortable-lists--list-accepted-type-value="work_package"></ul>
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-id-value="1" data-sortable-lists--list-accepted-type-value="work_package"></ul>
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
      '/projects/demo/backlogs/work_packages/1/move?optimistic=true',
      expect.objectContaining({ method: 'PUT' }),
    );
  });

  it('does nothing when the controller has no move URL template', async () => {
    const { targetList, firstSourceItem } = renderFixture({ moveUrlTemplate: null });

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('marks the root busy while moving an item without flagging lists aria-busy', async () => {
    let resolveMove:(response:Response) => void;

    fetchMock.mockImplementationOnce(() => {
      return new Promise<Response>((resolve) => {
        resolveMove = resolve;
      });
    });

    const { root, targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(root.dataset.sortableListsBusy).toEqual('true');
    // The reorder already happened; the await window contains no DOM change,
    // so lists must not claim to be busy (Turbo marks frames busy itself).
    expect(targetList.hasAttribute('aria-busy')).toBe(false);

    resolveMove!(new Response('', { status: 200 }));
    await flushPromises();

    expect(root.hasAttribute('data-sortable-lists-busy')).toBe(false);
    expect(targetList.hasAttribute('aria-busy')).toBe(false);
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

    resolveMove!(new Response('', { status: 200 }));
    await flushPromises();
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
    expect(typeof toastEvents[0].detail.message).toBe('string');
    expect(toastEvents[0].detail.type).toBe('error');
    expect(root.hasAttribute('data-sortable-lists-busy')).toBe(false);

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

  it('skips the rollback when a concurrent morph relocated the row before the move request fails', async () => {
    let rejectMove:(error:Error) => void;

    fetchMock.mockImplementationOnce(() => {
      return new Promise<Response>((_resolve, reject) => {
        rejectMove = reject;
      });
    });

    const { sourceList, targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    // The optimistic reorder has already happened while the move request is
    // still pending.
    expect(itemIds(targetList)).toEqual(['4', '5', '1']);

    // A concurrent morph (e.g. an unrelated list refresh) relocates the row
    // before the failure resolves. Its placement is fresher server state, so
    // the eventual rollback must yield to it rather than restoring the row
    // to where the optimistic move first put it.
    sourceList.append(firstSourceItem);

    rejectMove!(new Error('Network failure'));
    await flushPromises();

    expect(itemIds(sourceList)).toEqual(['2', '3', '1']);
    expect(itemIds(targetList)).toEqual(['4', '5']);
  });

  it('announces a same-list move with its absolute position', async () => {
    const { sourceList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, sourceList);

    expect(announcedMessages()).toEqual([
      ['Story 1 moved to position 3 of 3', { politeness: 'polite' }],
    ]);
  });

  it('announces a cross-list move with the target list name', async () => {
    const { targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(announcedMessages()).toEqual([
      ['Story 1 moved to Sprint 1, position 3 of 3', { politeness: 'polite' }],
    ]);
  });

  it('falls back to generic wording without item label and list name', async () => {
    const { targetList, firstSourceItem } = renderFixture();
    firstSourceItem.removeAttribute('data-sortable-lists--item-label-value');
    targetList.removeAttribute('data-sortable-lists--list-name-value');

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    expect(announcedMessages()).toEqual([
      ['Item moved to another list, position 3 of 3', { politeness: 'polite' }],
    ]);
  });

  it('announces absolute positions across a truncation marker', async () => {
    const { sourceList, firstSourceItem } = renderFixture();
    const markerRow = document.createElement('li');
    markerRow.setAttribute('data-sortable-lists-prev-item-id', '90');
    markerRow.setAttribute('data-sortable-lists-omitted-count', '40');
    sourceList.insertBefore(markerRow, sourceList.querySelector('[data-sortable-lists--item-id-value="3"]'));

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, sourceList);

    expect(announcedMessages()).toEqual([
      ['Story 1 moved to position 43 of 43', { politeness: 'polite' }],
    ]);
  });

  it('announces nothing for a drop at the current position', async () => {
    const { sourceList } = renderFixture();
    const lastSourceItem = sourceList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="3"]')!;

    await ctx.nextFrame();
    await dropCurrentItemOnList(lastSourceItem, sourceList);

    expect(announceSpy).not.toHaveBeenCalled();
  });

  it('stays silent on a 422, whose error flash announces server-side', async () => {
    fetchMock.mockResolvedValueOnce(new Response('', { status: 422 }));
    const { targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);
    await flushPromises();

    // Only the optimistic-placement announcement; no client failure message.
    expect(announcedMessages()).toEqual([
      ['Story 1 moved to Sprint 1, position 3 of 3', { politeness: 'polite' }],
    ]);
  });

  it('announces a verified rollback assertively on a network failure', async () => {
    fetchMock.mockRejectedValueOnce(new Error('Network failure'));
    const { targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);
    await flushPromises();

    expect(announcedMessages()).toEqual([
      ['Story 1 moved to Sprint 1, position 3 of 3', { politeness: 'polite' }],
      ['Move failed. Story 1 returned to its previous position.', { politeness: 'assertive' }],
    ]);
  });

  it('announces the fallback failure wording when the rollback is skipped', async () => {
    let rejectMove:(error:Error) => void;

    fetchMock.mockImplementationOnce(() => {
      return new Promise<Response>((_resolve, reject) => {
        rejectMove = reject;
      });
    });

    const { sourceList, targetList, firstSourceItem } = renderFixture();

    await ctx.nextFrame();
    await dropCurrentItemOnList(firstSourceItem, targetList);

    // A concurrent morph (e.g. an unrelated list refresh) relocates the row
    // before the move request fails, so the fresher-morph guard skips the
    // rollback (same setup as the rollback-skip test above).
    sourceList.append(firstSourceItem);

    rejectMove!(new Error('Network failure'));
    await flushPromises();

    expect(announcedMessages()[1]).toEqual(
      ['Move failed. Check the item\'s current position.', { politeness: 'assertive' }],
    );
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

  it('hands the root reference to connected list, item, and scrollable controllers', async () => {
    const {
      root, sourceList, scrollable, firstSourceItem,
    } = renderFixture();
    await ctx.nextFrame();
    // Outlet connections happen after the controller frame; a second frame
    // ensures the hand-over callbacks have fired.
    await ctx.nextFrame();

    const listController = ctx.application.getControllerForElementAndIdentifier(sourceList, 'sortable-lists--list') as unknown as { ['root']?:unknown };
    const itemController = ctx.application.getControllerForElementAndIdentifier(firstSourceItem, 'sortable-lists--item') as unknown as { ['root']?:unknown };
    const scrollableController = ctx.application.getControllerForElementAndIdentifier(scrollable, 'sortable-lists--scrollable') as unknown as { ['root']?:unknown };
    const rootController = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists');

    expect(listController.root).toBe(rootController);
    expect(itemController.root).toBe(rootController);
    expect(scrollableController.root).toBe(rootController);
  });

  describe('registration heal after a morph', () => {
    async function renderedFixtureWithCallCounts() {
      const fixtureElements = renderFixture();
      await ctx.nextFrame();
      // Outlet connections happen after the controller frame; a second frame
      // ensures the hand-over callbacks have fired.
      await ctx.nextFrame();

      const { dropTargetForElements, draggable } = vi.mocked(await import('@atlaskit/pragmatic-drag-and-drop/element/adapter'));
      const { autoScrollForElements } = vi.mocked(await import('@atlaskit/pragmatic-drag-and-drop-auto-scroll/element'));
      return {
        ...fixtureElements,
        dropTargetForElements,
        draggable,
        autoScrollForElements,
      };
    }

    function morph(target:HTMLElement) {
      target.dispatchEvent(new CustomEvent('turbo:morph-element', { bubbles: true }));
    }

    const flushMicrotasks = () => Promise.resolve();

    it('re-registers items, lists and scrollables from controller state', async () => {
      const {
        firstSourceItem, sourceList, scrollable, dropTargetForElements, draggable, autoScrollForElements,
      } = await renderedFixtureWithCallCounts();
      const itemRegistrations = () => dropTargetForElements.mock.calls.filter(([options]) => options.element === firstSourceItem).length;
      const listRegistrations = () => dropTargetForElements.mock.calls.filter(([options]) => options.element === sourceList).length;
      const scrollableRegistrations = () => autoScrollForElements.mock.calls.filter(([options]) => options.element === scrollable).length;
      const draggableRegistrations = () => draggable.mock.calls.filter(([options]) => options.element === firstSourceItem).length;

      morph(firstSourceItem);
      await flushMicrotasks();

      expect(itemRegistrations()).toEqual(2);
      expect(listRegistrations()).toEqual(2);
      expect(scrollableRegistrations()).toEqual(2);
      expect(draggableRegistrations()).toEqual(2);
    });

    it('coalesces one morph batch into a single heal', async () => {
      const { root, firstSourceItem, dropTargetForElements } = await renderedFixtureWithCallCounts();
      const itemRegistrations = () => dropTargetForElements.mock.calls.filter(([options]) => options.element === firstSourceItem).length;

      morph(root);
      morph(firstSourceItem);
      morph(firstSourceItem);
      await flushMicrotasks();

      expect(itemRegistrations()).toEqual(2);
    });

    it('heals again for a later morph', async () => {
      const { firstSourceItem, dropTargetForElements } = await renderedFixtureWithCallCounts();
      const itemRegistrations = () => dropTargetForElements.mock.calls.filter(([options]) => options.element === firstSourceItem).length;

      morph(firstSourceItem);
      await flushMicrotasks();
      morph(firstSourceItem);
      await flushMicrotasks();

      expect(itemRegistrations()).toEqual(3);
    });

    it('re-hands the root reference to children that lost it', async () => {
      const { root, firstSourceItem } = await renderedFixtureWithCallCounts();
      const itemController = ctx.application.getControllerForElementAndIdentifier(firstSourceItem, 'sortable-lists--item') as unknown as { root?:unknown; disconnectRoot():void };
      const rootController = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists');

      // A morph-replaced element's controller misses the outlet-connected
      // hand-over; losing the root reference stands in for that here.
      itemController.disconnectRoot();
      expect(itemController.root).toBeUndefined();

      morph(firstSourceItem);
      await flushMicrotasks();

      expect(itemController.root).toBe(rootController);
    });

    it('does not adopt outlet-matched children outside its own element', async () => {
      // An outlet selector is document-scoped, so a carelessly broad selector
      // can match children of another root. The heal must only repair its own.
      fixture.innerHTML = `
        <div
          id="heal-root"
          data-controller="sortable-lists"
          data-sortable-lists-move-url-template-value="/move/{id}"
          data-sortable-lists-sortable-lists--list-outlet="[data-controller~='sortable-lists--list']"
          data-sortable-lists-sortable-lists--item-outlet="[data-controller~='sortable-lists--item']"
          data-sortable-lists-sortable-lists--scrollable-outlet="[data-controller~='sortable-lists--scrollable']"
        >
          <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-id-value="1" data-sortable-lists--list-accepted-type-value="work_package"></ul>
        </div>
        <ul id="outside-list" data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-id-value="2" data-sortable-lists--list-accepted-type-value="work_package"></ul>
      `;
      const root = fixture.querySelector<HTMLElement>('#heal-root')!;
      const outsideList = fixture.querySelector<HTMLElement>('#outside-list')!;
      outsideList.append(itemRow('9'));
      const outsideItem = outsideList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="9"]')!;

      await ctx.nextFrame();
      await ctx.nextFrame();

      const outsideItemController = ctx.application.getControllerForElementAndIdentifier(outsideItem, 'sortable-lists--item') as unknown as { root?:unknown; disconnectRoot():void };
      outsideItemController.disconnectRoot();

      morph(root);
      await flushMicrotasks();

      expect(outsideItemController.root).toBeUndefined();
    });
  });

  it('moves an item down through the optimistic path', async () => {
    const { root, sourceList, firstSourceItem } = renderFixture();
    await ctx.nextFrame();

    const controller = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists') as SortableListsControllerType;
    controller.moveInDirection(firstSourceItem, 'down');
    await flushPromises();

    // '1' started first; moving down puts it after '2'.
    expect(itemIds(sourceList)).toEqual(['2', '1', '3']);
    expect(fetchMock).toHaveBeenCalledOnce();
    const body = fetchMock.mock.lastCall?.[1] as { body:FormData };
    expect(body.body.get('prev_id')).toBe('2');
  });

  it('reports per-direction move availability for gating', async () => {
    const { root, firstSourceItem } = renderFixture();
    await ctx.nextFrame();
    const controller = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists') as SortableListsControllerType;

    // First item: down/bottom available, up/top not.
    expect(controller.moveAvailability(firstSourceItem)).toEqual({
      top: false, up: false, down: true, bottom: true,
    });
  });

  it('reports null availability for an item outside any owned list', async () => {
    const { root } = renderFixture();
    await ctx.nextFrame();
    const controller = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists') as SortableListsControllerType;

    expect(controller.moveAvailability(document.createElement('li'))).toBeNull();
  });

  it('resolves the owning list element of an item for the drag payload', async () => {
    const { root, sourceList, firstSourceItem } = renderFixture();
    await ctx.nextFrame();
    const controller = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists') as SortableListsControllerType;

    expect(controller.ownerListElementOf(firstSourceItem)).toBe(sourceList);
    expect(controller.ownerListElementOf(document.createElement('li'))).toBeNull();
  });

  describe('nested list topology', () => {
    it('resolves the source row of a nested item against its innermost list', async () => {
      const { fieldList, firstFieldItem } = renderNestedFixture();

      await ctx.nextFrame();
      await dropCurrentItemOnList(firstFieldItem, fieldList);

      // The dragged custom_field item's own row moved within its innermost
      // (field) list; the outer section row it lives under is untouched.
      expect(directItemIds(fieldList)).toEqual(['cf2', 'cf1']);

      const options = fetchMock.mock.lastCall?.[1] as { body:FormData };
      expect(options.body.get('list_type')).toEqual('custom_field');
      expect(options.body.get('list_id')).toEqual('s1');
    });

    it('resolves a section row that is not an <li>', async () => {
      const { sectionList, sectionItem } = renderNestedFixture();

      await ctx.nextFrame();
      // A list-only drop onto the section list's own default ('end')
      // position: with two section rows this reorders them, so it is a real
      // move rather than a same-position no-op.
      await dropCurrentItemOnList(sectionItem, sectionList);

      // closest('li') on a <div> row returns null and the drop would
      // silently be ignored; a fired move proves the row resolved.
      expect(fetchMock).toHaveBeenCalledOnce();
      expect(directItemIds(sectionList)).toEqual(['s2', 's1']);

      const options = fetchMock.mock.lastCall?.[1] as { body:FormData };
      expect(options.body.get('list_type')).toEqual('section');
      expect(options.body.get('list_id')).toEqual('1');
    });
  });

  describe('per-type move URL map', () => {
    it('resolves the drop move URL from the per-type template map', async () => {
      const { fieldList, sectionList } = renderTypeMapFixture();
      fieldList.append(fieldRow('42'), fieldRow('99'));
      sectionList.append(sectionRow('3'), sectionRow('8'));

      await ctx.nextFrame();

      const fieldItem = fieldList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="42"]')!;
      await dropCurrentItemOnList(fieldItem, fieldList, 'custom_field');

      expect(fetchMock).toHaveBeenCalledWith(
        expect.stringMatching(/^\/fields\/42\/drop/),
        expect.objectContaining({ method: 'PUT' }),
      );

      fetchMock.mockClear();

      const sectionItem = sectionList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="3"]')!;
      await dropCurrentItemOnList(sectionItem, sectionList, 'section');

      expect(fetchMock).toHaveBeenCalledWith(
        expect.stringMatching(/^\/sections\/3\/drop/),
        expect.objectContaining({ method: 'PUT' }),
      );
    });

    it('falls back to the single template for an unmapped type', async () => {
      const { fieldList } = renderTypeMapFixture({
        moveUrlTemplates: '{"section":"/sections/{id}/drop"}',
        moveUrlTemplate: '/move/{id}',
      });
      fieldList.append(fieldRow('7'), fieldRow('8'));

      await ctx.nextFrame();

      const fieldItem = fieldList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="7"]')!;
      await dropCurrentItemOnList(fieldItem, fieldList, 'custom_field');

      expect(fetchMock).toHaveBeenCalledWith(
        expect.stringMatching(/^\/move\/7/),
        expect.objectContaining({ method: 'PUT' }),
      );
    });

    it('resolves the menu move URL from the map', async () => {
      const { root, fieldList } = renderTypeMapFixture();
      fieldList.append(fieldRow('1'), fieldRow('2'));

      await ctx.nextFrame();

      const controller = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists') as SortableListsControllerType;
      const secondFieldItem = fieldList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="2"]')!;
      controller.moveInDirection(secondFieldItem, 'up');
      await flushPromises();

      expect(fetchMock).toHaveBeenCalledWith(
        expect.stringMatching(/^\/fields\//),
        expect.objectContaining({ method: 'PUT' }),
      );
    });
  });
});
