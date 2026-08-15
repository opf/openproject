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

vi.mock('@atlaskit/pragmatic-drag-and-drop-auto-scroll/element', () => ({
  autoScrollForElements: vi.fn(() => vi.fn()),
}));

// This spec mounts the real item controller, which pulls in these modules.
// Tests share one module registry (the runner does not isolate spec files),
// so importing the real versions here would leak into the item controller
// spec and break its spies. Mock them to keep the shared cache inert.
vi.mock('@atlaskit/pragmatic-drag-and-drop/combine', () => ({
  combine: vi.fn((...cleanups:(() => void)[]) => vi.fn(() => {
    cleanups.forEach((cleanup) => cleanup());
  })),
}));

vi.mock('@atlaskit/pragmatic-drag-and-drop/prevent-unhandled', () => ({
  preventUnhandled: { start: vi.fn(), stop: vi.fn() },
}));

vi.mock('@atlaskit/pragmatic-drag-and-drop/element/set-custom-native-drag-preview', () => ({
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
    selectionEnabled = false,
  }:{ moveUrlTemplate?:string|null; optimistic?:boolean; selectionEnabled?:boolean } = {}) {
    fixture.innerHTML = `
      <div
        id="sortable-root"
        data-controller="sortable-lists"
        ${moveUrlTemplate ? `data-sortable-lists-move-url-template-value="${moveUrlTemplate}"` : ''}
        ${optimistic ? 'data-sortable-lists-optimistic-value="true"' : ''}
        ${selectionEnabled ? 'data-sortable-lists-selection-enabled-value="true"' : ''}
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
      root,
      sourceList,
      targetList,
      scrollable,
      firstSourceItem: sourceList.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="1"]')!,
      items: Array.from(root.querySelectorAll<HTMLElement>('[data-sortable-lists--item-id-value]')),
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

  // Layered on renderFixture, plus selection and a tabindex per item. The
  // value is set at creation time: Stimulus picks up an attribute mutated
  // after connect through its async MutationObserver channel, too late for a
  // synchronous test. The tabindex mirrors Backlogs cards, whose item element
  // is itself focusable.
  function renderSelectableRoot({
    moveUrlTemplate = '/move/{id}',
  }:{ moveUrlTemplate?:string|null } = {}) {
    const fixtureElements = renderFixture({ moveUrlTemplate, selectionEnabled: true });
    fixtureElements.items.forEach((item) => item.setAttribute('tabindex', '0'));

    return fixtureElements;
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
            selection: {
              cleared: 'Selection cleared.',
              not_selectable: 'Selection unchanged. This item takes no part in this list\'s ordering.',
              range_blocked: 'Selection unchanged. That range contains an item that takes no part in this list\'s ordering.',
              range_restarted: {
                one: 'Could not extend the range. 1 item selected.',
                other: 'Could not extend the range. %{count} items selected.',
              },
              range_unavailable: 'Selection unchanged. Expand this list to select that range.',
              selected: {
                one: '1 item selected.',
                other: '%{count} items selected.',
              },
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

  it('refuses a directional move for a non-movable item', async () => {
    const { root, sourceList, firstSourceItem } = renderFixture();
    firstSourceItem.setAttribute('data-sortable-lists--item-mobility-value', 'fixed');
    await ctx.nextFrame();

    const controller = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists') as SortableListsControllerType;
    controller.moveInDirection(firstSourceItem, 'down');
    await flushPromises();

    expect(itemIds(sourceList)).toEqual(['1', '2', '3']);
    expect(fetchMock).not.toHaveBeenCalled();
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

  // A card that takes no part in ordering must not be offered a move the
  // click path would then refuse.
  it('reports no available direction for a non-movable item', async () => {
    const { root, firstSourceItem } = renderFixture();
    firstSourceItem.setAttribute('data-sortable-lists--item-mobility-value', 'fixed');
    await ctx.nextFrame();
    const controller = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists') as SortableListsControllerType;

    expect(controller.moveAvailability(firstSourceItem)).toEqual({
      top: false, up: false, down: false, bottom: false,
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

  // Collapsing a batch and selecting the dragged card are different things:
  // with nothing selected, a drag must not manufacture a one-card batch.
  it('leaves an empty selection empty when a drag starts with nothing selected', async () => {
    const { root, firstSourceItem } = renderSelectableRoot();
    await ctx.nextFrame();
    const controller = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists') as SortableListsControllerType;

    controller.collapseSelectionForDrag(firstSourceItem);

    expect(document.querySelector('[data-batch-selected]')).toBeNull();
  });

  // A drag that narrows a larger batch to one card is a count change a
  // screen-reader user has to hear.
  it('announces the new count when a drag collapses a multi-card batch', async () => {
    const { root, items } = renderSelectableRoot();
    await ctx.nextFrame();
    const controller = ctx.application.getControllerForElementAndIdentifier(root, 'sortable-lists') as SortableListsControllerType;
    items[0].dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
    items[1].dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, metaKey: true }));
    items[2].dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, metaKey: true }));
    announceSpy.mockClear();

    controller.collapseSelectionForDrag(items[0]);

    expect(items.filter((item) => item.hasAttribute('data-batch-selected'))).toEqual([items[0]]);
    expect(announceSpy.mock.calls.map((call) => [call[0], call[1]])).toEqual([
      ['1 item selected.', { politeness: 'polite' }],
    ]);
  });

  const click = (element:HTMLElement, init:MouseEventInit = {}) => {
    element.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, ...init }));
  };

  // A gesture the root leaves alone keeps its native default, so a real
  // anchor would navigate the test page away. Cancelled in the bubble phase,
  // after the root's capture-phase listener has had its turn.
  const clickWithoutNavigating = (element:HTMLElement, init:MouseEventInit = {}) => {
    const blockNavigation = (event:Event) => event.preventDefault();
    window.addEventListener('click', blockNavigation, { once: true });

    click(element, init);

    window.removeEventListener('click', blockNavigation);
  };

  const isSelected = (element:HTMLElement) => element.hasAttribute('data-batch-selected');

  // A restored page brings its markup back but not the model. Not driven
  // through turbo:before-cache: that also fires for the details-pane
  // navigation, where clearing would strip a live batch.
  it('clears stale batch presentation left in the DOM when it connects', async () => {
    fixture.innerHTML = `
      <div id="stale-root"
           data-controller="sortable-lists"
           data-sortable-lists-selection-enabled-value="true"
           data-sortable-lists-sortable-lists--item-outlet="#stale-root [data-controller~='sortable-lists--item']">
        <ul data-controller="sortable-lists--list" data-sortable-lists--list-type-value="sprint" data-sortable-lists--list-id-value="1">
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="1" data-sortable-lists--item-type-value="work_package" data-batch-selected></li>
        </ul>
      </div>
    `;
    const stale = fixture.querySelector<HTMLElement>('#stale-root')!;
    const row = stale.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="1"]')!;
    expect(row.hasAttribute('data-batch-selected')).toBe(true);

    await ctx.nextFrame();

    expect(row.hasAttribute('data-batch-selected')).toBe(false);
  });

  it('selects only the clicked card on a plain click', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();

    click(items[0]);

    expect(isSelected(items[0])).toBe(true);
    expect(isSelected(items[1])).toBe(false);
  });

  it('lets a plain click continue to the navigation handler', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    const event = new MouseEvent('click', { bubbles: true, cancelable: true });

    items[0].dispatchEvent(event);

    expect(event.defaultPrevented).toBe(false);
  });

  it('lets a plain click on a non-movable card continue to navigate without selecting', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[0].setAttribute('data-sortable-lists--item-mobility-value', 'fixed');
    const event = new MouseEvent('click', { bubbles: true, cancelable: true });

    items[0].dispatchEvent(event);

    expect(isSelected(items[0])).toBe(false);
    expect(event.defaultPrevented).toBe(false);
  });

  // A fixed card does not join the batch, but the click still opens its
  // details pane, so it must not leave an unrelated batch behind.
  it('clears an existing batch on a plain click that lands on a non-movable card', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    click(items[1], { metaKey: true });
    items[2].setAttribute('data-sortable-lists--item-mobility-value', 'fixed');
    const event = new MouseEvent('click', { bubbles: true, cancelable: true });

    items[2].dispatchEvent(event);

    expect(items.some(isSelected)).toBe(false);
    expect(event.defaultPrevented).toBe(false);
  });

  it('announces the new count when a plain click collapses a multi-card batch', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    click(items[1], { metaKey: true });
    click(items[2], { metaKey: true });
    announceSpy.mockClear();

    click(items[0]);

    expect(items.filter(isSelected)).toEqual([items[0]]);
    expect(announcedMessages()).toEqual([
      ['1 item selected.', { politeness: 'polite' }],
    ]);
  });

  // The click also opens the details pane, which is its own feedback.
  it('stays silent on a plain click that does not change the selected count', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    announceSpy.mockClear();

    click(items[1]);

    expect(items.filter(isSelected)).toEqual([items[1]]);
    expect(announceSpy).not.toHaveBeenCalled();
  });

  // An unconsumed modified gesture would reach the card's own click handler
  // and open the details pane on a selection toggle.
  it('consumes a modified click during a busy move without changing the selection', async () => {
    const { root, items } = renderSelectableRoot();
    await ctx.nextFrame();
    root.setAttribute('data-sortable-lists-busy', 'true');
    const event = new MouseEvent('click', { bubbles: true, cancelable: true, metaKey: true });

    items[0].dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
    expect(items.some(isSelected)).toBe(false);
  });

  it('toggles a card without navigating on a meta click', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    const event = new MouseEvent('click', { bubbles: true, cancelable: true, metaKey: true });

    click(items[0]);
    items[1].dispatchEvent(event);

    expect(isSelected(items[0])).toBe(true);
    expect(isSelected(items[1])).toBe(true);
    expect(event.defaultPrevented).toBe(true);
  });

  it('selects a range from the anchor on a shift click', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();

    click(items[0]);
    click(items[2], { shiftKey: true });

    expect(items.filter(isSelected)).toEqual([items[0], items[1], items[2]]);
  });

  it('keeps the anchor fixed so a range can be resized', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();

    click(items[0]);
    click(items[2], { shiftKey: true });
    click(items[1], { shiftKey: true });

    expect(items.filter(isSelected)).toEqual([items[0], items[1]]);
  });

  it('starts a single selection when shift is pressed without an anchor', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();

    click(items[1], { shiftKey: true });

    expect(items.filter(isSelected)).toEqual([items[1]]);
  });

  // The count rule alone would fall silent whenever the prior selection was
  // already a single card, leaving the failed range with no feedback.
  it('announces a distinct message when a cross-list Shift-click restarts the range', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    announceSpy.mockClear();

    click(items[3], { shiftKey: true });

    expect(items.filter(isSelected)).toEqual([items[3]]);
    expect(announcedMessages()).toEqual([
      ['Could not extend the range. 1 item selected.', { politeness: 'polite' }],
    ]);
  });

  // Same restart, reached the other way: an anchor pruned after a morph
  // leaves a one-card selection with nothing to range from.
  it('announces a distinct message when a Shift-click restarts the range after its anchor was pruned', async () => {
    const { root, items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    click(items[1], { metaKey: true });
    items[1].remove();
    morphRoot(root);
    await ctx.nextFrame();
    announceSpy.mockClear();

    click(items[2], { shiftKey: true });

    // items[1] was removed from the document above; a stale reference to it
    // would still carry the attribute it had before removal, so membership
    // is checked on the two live cards rather than filtering the whole
    // `items` array.
    expect(isSelected(items[0])).toBe(false);
    expect(isSelected(items[2])).toBe(true);
    expect(announcedMessages()).toEqual([
      ['Could not extend the range. 1 item selected.', { politeness: 'polite' }],
    ]);
  });

  it('tells the user to expand the list when a range crosses a truncation marker', async () => {
    const { sourceList, items } = renderSelectableRoot();
    await ctx.nextFrame();
    const marker = document.createElement('li');
    marker.setAttribute('data-sortable-lists-prev-item-id', '1');
    marker.setAttribute('data-sortable-lists-omitted-count', '9');
    sourceList.insertBefore(marker, items[1]);

    click(items[0]);
    announceSpy.mockClear();
    click(items[2], { shiftKey: true });

    expect(items.filter(isSelected)).toEqual([items[0]]);
    expect(announcedMessages()).toEqual([
      ['Selection unchanged. Expand this list to select that range.', { politeness: 'polite' }],
    ]);
  });

  // Expanding the list can never resolve a non-movable card in the span.
  it('tells the user a locked card blocks the range rather than to expand the list', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[1].setAttribute('data-sortable-lists--item-mobility-value', 'fixed');

    click(items[0]);
    announceSpy.mockClear();
    click(items[2], { shiftKey: true });

    expect(items.filter(isSelected)).toEqual([items[0]]);
    expect(announcedMessages()).toEqual([
      ['Selection unchanged. That range contains an item that takes no part in this list\'s ordering.', { politeness: 'polite' }],
    ]);
  });

  it('preserves the batch and announces when a non-movable card is meta clicked', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[1].setAttribute('data-sortable-lists--item-mobility-value', 'fixed');
    const event = new MouseEvent('click', { bubbles: true, cancelable: true, metaKey: true });

    click(items[0]);
    announceSpy.mockClear();
    items[1].dispatchEvent(event);

    expect(items.filter(isSelected)).toEqual([items[0]]);
    expect(event.defaultPrevented).toBe(true);
    expect(announcedMessages()).toEqual([
      ['Selection unchanged. This item takes no part in this list\'s ordering.', { politeness: 'polite' }],
    ]);
  });

  it('ignores gestures that start on an interactive descendant', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    const link = document.createElement('a');
    link.href = '/somewhere';
    items[0].appendChild(link);

    clickWithoutNavigating(link, { metaKey: true });

    expect(items.some(isSelected)).toBe(false);
  });

  // Stopping the walk at the item would classify every gesture on a Backlogs
  // card as interactive, since the card itself carries tabindex. Only
  // observable once the focus host is a distinct, nested element.
  it('selects when a gesture lands on a non-interactive descendant of a nested focus host', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    const focusHost = document.createElement('div');
    focusHost.setAttribute('data-sortable-lists--item-target', 'focus');
    focusHost.tabIndex = 0;
    const label = document.createElement('span');
    focusHost.appendChild(label);
    items[0].appendChild(focusHost);

    click(label);

    expect(isSelected(items[0])).toBe(true);
  });

  // A nested focus host sits below the item, so a gesture landing elsewhere
  // on the row never reaches it walking up: stopping there unconditionally
  // would leave the walk unbounded past the item.
  it('still selects when a gesture lands on the row outside a nested focus host', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    const focusHost = document.createElement('div');
    focusHost.setAttribute('data-sortable-lists--item-target', 'focus');
    focusHost.tabIndex = 0;
    items[0].appendChild(focusHost);

    click(items[0]);

    expect(isSelected(items[0])).toBe(true);
  });

  it('does not select at all when selection is not enabled', async () => {
    const { items } = renderFixture();
    await ctx.nextFrame();

    click(items[0]);

    expect(items.some(isSelected)).toBe(false);
  });

  // A Turbo morph can flip the permission-gated value on a live root without
  // reconnecting the controller, so the gestures follow the flip.
  it('stops selecting when selection is disabled on the live root', async () => {
    const { root, items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    expect(isSelected(items[0])).toBe(true);

    root.setAttribute('data-sortable-lists-selection-enabled-value', 'false');
    await ctx.nextFrame();

    expect(items.some(isSelected)).toBe(false);
    click(items[1]);
    expect(items.some(isSelected)).toBe(false);
  });

  it('starts selecting when selection is enabled on the live root', async () => {
    const { root, items } = renderFixture();
    await ctx.nextFrame();
    click(items[0]);
    expect(items.some(isSelected)).toBe(false);

    items.forEach((item) => item.setAttribute('tabindex', '0'));
    root.setAttribute('data-sortable-lists-selection-enabled-value', 'true');
    await ctx.nextFrame();

    click(items[0]);
    expect(isSelected(items[0])).toBe(true);
  });

  // A cached root re-attaching reconnects the same controller instance, and
  // Stimulus fires no value callback for an unchanged attribute.
  it('restores selection when the same root reconnects', async () => {
    const { root, items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    expect(isSelected(items[0])).toBe(true);

    root.remove();
    await ctx.nextFrame();
    fixture.append(root);
    await ctx.nextFrame();

    click(items[1]);
    expect(isSelected(items[1])).toBe(true);
  });

  const keydown = (target:HTMLElement, key:string, init:KeyboardEventInit = {}) => {
    const event = new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true, ...init });
    target.dispatchEvent(event);
    return event;
  };

  it('toggles the focused card on Space', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[0].focus();

    const event = keydown(items[0], ' ');

    expect(isSelected(items[0])).toBe(true);
    expect(event.defaultPrevented).toBe(true);
  });

  it('extends the range on Shift+Space', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    items[2].focus();

    keydown(items[2], ' ', { shiftKey: true });

    expect(items.filter(isSelected)).toEqual([items[0], items[1], items[2]]);
  });

  it('moves focus within the list on ArrowDown', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[0].focus();

    keydown(items[0], 'ArrowDown');

    expect(document.activeElement).toBe(items[1]);
  });

  // An unconsumed arrow falls through to native scrolling, moving the page
  // while focus stays put.
  it('consumes ArrowUp at the first card even though focus cannot move', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[0].focus();

    const event = keydown(items[0], 'ArrowUp');

    expect(document.activeElement).toBe(items[0]);
    expect(event.defaultPrevented).toBe(true);
  });

  it('consumes ArrowDown at the last card of a list even though focus cannot move', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[2].focus();

    const event = keydown(items[2], 'ArrowDown');

    expect(document.activeElement).toBe(items[2]);
    expect(event.defaultPrevented).toBe(true);
  });

  it('extends the range while moving focus on Shift+ArrowDown', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    items[0].focus();

    keydown(items[0], 'ArrowDown', { shiftKey: true });

    expect(document.activeElement).toBe(items[1]);
    expect(items.filter(isSelected)).toEqual([items[0], items[1]]);
  });

  it('moves focus to the list boundaries on Home and End', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[1].focus();

    keydown(items[1], 'End');
    expect(document.activeElement).toBe(items[2]);

    keydown(items[2], 'Home');
    expect(document.activeElement).toBe(items[0]);
  });

  // Same boundary-scroll problem as the plain arrows above.
  it('consumes Home at the first card even though focus cannot move', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[0].focus();

    const event = keydown(items[0], 'Home');

    expect(document.activeElement).toBe(items[0]);
    expect(event.defaultPrevented).toBe(true);
  });

  it('consumes End at the last card even though focus cannot move', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[2].focus();

    const event = keydown(items[2], 'End');

    expect(document.activeElement).toBe(items[2]);
    expect(event.defaultPrevented).toBe(true);
  });

  // The design's keyboard table specifies the first/last *movable* card for
  // Home/End (unlike plain arrow steps, which are not qualified that way).
  it('skips a non-movable card when moving to the list boundary on End', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[2].setAttribute('data-sortable-lists--item-mobility-value', 'fixed');
    items[0].focus();

    keydown(items[0], 'End');

    expect(document.activeElement).toBe(items[1]);
  });

  // Focus cannot move further, but the range still resizes to the boundary.
  it('resizes the range to the list boundary on Shift+Home even when focus cannot move', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[2]);
    items[2].focus();
    keydown(items[2], 'ArrowUp');
    keydown(items[1], 'ArrowUp');

    keydown(items[0], 'Home', { shiftKey: true });

    expect(items.filter(isSelected)).toEqual([items[0], items[1], items[2]]);
  });

  // The fixture spans two lists: items[0..2] in the source, items[3..4] in
  // the target.
  it('selects every movable card in the focused list on meta A', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[1].setAttribute('data-sortable-lists--item-mobility-value', 'fixed');
    items[0].focus();

    keydown(items[0], 'a', { metaKey: true });

    const selected = items.filter(isSelected);
    expect(selected).toEqual([items[0], items[2]]);
    expect(selected).not.toContain(items[1]);
  });

  // Would pass under a root-wide select-all.
  it('leaves movable cards of other lists unselected on meta A', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[0].focus();

    keydown(items[0], 'a', { metaKey: true });

    expect(isSelected(items[3])).toBe(false);
    expect(isSelected(items[4])).toBe(false);
  });

  it('selects every movable card of the focused list on ctrl A', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[0].focus();

    keydown(items[0], 'a', { ctrlKey: true });

    expect(items.filter(isSelected)).toEqual([items[0], items[1], items[2]]);
  });

  it('does nothing on a bare "a" without a modifier', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[0].focus();

    const event = keydown(items[0], 'a');

    expect(items.some(isSelected)).toBe(false);
    expect(event.defaultPrevented).toBe(false);
  });

  // Focusing something other than the first card rules out an anchor that
  // merely coincides with a document-order fallback.
  it('anchors the batch on the focused card after meta A when it is movable', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[2].focus();

    keydown(items[2], 'a', { metaKey: true });
    keydown(items[0], ' ', { shiftKey: true });

    expect(items.filter(isSelected)).toEqual([items[0], items[1], items[2]]);
  });

  // A subsequent Shift gesture proves the fallback anchor is set: no anchor
  // at all would collapse the range to a single card.
  it('anchors the batch on the first movable card after meta A when the focused card is not movable', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[0].setAttribute('data-sortable-lists--item-mobility-value', 'fixed');
    items[0].focus();

    keydown(items[0], 'a', { metaKey: true });
    keydown(items[2], ' ', { shiftKey: true });

    expect(items.filter(isSelected)).toEqual([items[1], items[2]]);
  });

  it('clears the batch on Escape', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    items[0].focus();

    keydown(items[0], 'Escape');

    expect(items.some(isSelected)).toBe(false);
  });

  // Escape clears local state only, so the busy gate must not swallow it.
  it('clears the batch on Escape even during a busy move', async () => {
    const { root, items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    items[0].focus();
    root.setAttribute('data-sortable-lists-busy', 'true');

    keydown(items[0], 'Escape');

    expect(items.some(isSelected)).toBe(false);
  });

  // An unconsumed Escape still reaches dialogs and menus.
  it('leaves Escape unconsumed when there is nothing to clear', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[0].focus();

    const event = keydown(items[0], 'Escape');

    expect(event.defaultPrevented).toBe(false);
  });

  // BatchSelection#toggle re-bases the anchor even on a deselect, so an
  // emptied selection leaves one behind. The Shift gesture below would range
  // from it had Escape not dropped it.
  it('clears the stale anchor left by a deselect, not just a visible selection', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[0].focus();
    keydown(items[0], ' ');
    keydown(items[0], ' ');

    keydown(items[0], 'Escape');
    keydown(items[2], ' ', { shiftKey: true });

    expect(items.filter(isSelected)).toEqual([items[2]]);
  });

  // A click on empty column space focuses nothing, and Escape there still
  // means "drop the selection".
  it('clears the batch on Escape when focus has left the root entirely', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);

    keydown(document.body, 'Escape');

    expect(items.some(isSelected)).toBe(false);
  });

  // An interactive descendant keeps its own clicks and Space, but Escape
  // still belongs to the selection.
  it('clears the batch on Escape from a link inside a card', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    const link = document.createElement('a');
    link.href = '#';
    items[1].append(link);

    keydown(link, 'Escape');

    expect(items.some(isSelected)).toBe(false);
  });

  it('leaves Escape inside an open menu to the menu', async () => {
    const { root, items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    const menu = document.createElement('div');
    menu.setAttribute('role', 'menu');
    const menuButton = document.createElement('button');
    menu.append(menuButton);
    root.append(menu);

    const event = keydown(menuButton, 'Escape');

    expect(isSelected(items[0])).toBe(true);
    expect(event.defaultPrevented).toBe(false);
  });

  it('ignores an Escape another handler already consumed', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    click(items[0]);
    items[1].addEventListener('keydown', (event) => event.preventDefault(), { once: true });

    keydown(items[1], 'Escape');

    expect(isSelected(items[0])).toBe(true);
  });

  it('leaves Enter to the navigation handler', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    items[0].focus();

    const event = keydown(items[0], 'Enter');

    expect(event.defaultPrevented).toBe(false);
  });

  it('ignores keys from an interactive descendant', async () => {
    const { items } = renderSelectableRoot();
    await ctx.nextFrame();
    const input = document.createElement('input');
    items[0].appendChild(input);
    input.focus();

    keydown(input, ' ');

    expect(items.some(isSelected)).toBe(false);
  });

  function morphRoot(root:HTMLElement) {
    root.dispatchEvent(new CustomEvent('turbo:morph-element', { bubbles: true }));
  }

  describe('reconciling the batch after a morph', () => {
    it('reapplies the batch presentation after a morph strips it', async () => {
      const { root, items } = renderSelectableRoot();
      await ctx.nextFrame();
      click(items[0]);
      items[0].removeAttribute('data-batch-selected');

      morphRoot(root);
      await ctx.nextFrame();

      expect(isSelected(items[0])).toBe(true);
    });

    it('clears a stale marker the morph preserved', async () => {
      const { root, items } = renderSelectableRoot();
      await ctx.nextFrame();
      items[2].setAttribute('data-batch-selected', '');

      morphRoot(root);
      await ctx.nextFrame();

      expect(isSelected(items[2])).toBe(false);
    });

    it('announces the new count when a morph prune removes a selected card', async () => {
      const { root, items } = renderSelectableRoot();
      await ctx.nextFrame();
      click(items[0]);
      click(items[1], { metaKey: true });
      click(items[2], { metaKey: true });
      items[1].remove();
      announceSpy.mockClear();

      morphRoot(root);
      await ctx.nextFrame();

      expect(announcedMessages()).toEqual([
        ['2 items selected.', { politeness: 'polite' }],
      ]);
    });

    // renderSelection runs on every morph and decides from membership alone,
    // so a prune that drops nothing has to stay silent by itself.
    it('stays silent when a morph prunes nothing', async () => {
      const { root, items } = renderSelectableRoot();
      await ctx.nextFrame();
      click(items[0]);
      click(items[1], { metaKey: true });
      announceSpy.mockClear();

      morphRoot(root);
      await ctx.nextFrame();

      expect(announceSpy).not.toHaveBeenCalled();
    });

    // selectedIds() filters to elements still in the document, so it would
    // pass even with the model unpruned. The anchor is the one place an
    // unpruned model is observable: a dangling one makes the Shift+click
    // below report an unavailable range instead of restarting the selection.
    it('drops a removed member and its stale anchor from the model', async () => {
      const { root, items } = renderSelectableRoot();
      await ctx.nextFrame();
      click(items[0]);
      click(items[1], { metaKey: true });
      items[1].remove();

      morphRoot(root);
      await ctx.nextFrame();
      click(items[2], { shiftKey: true });

      expect(isSelected(items[0])).toBe(false);
      expect(isSelected(items[2])).toBe(true);
    });
  });
});
