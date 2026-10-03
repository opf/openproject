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

import { selectionKey } from 'core-common/batch-selection';
import { type ListTopology, sortableListData } from './drag-and-drop';
import { listKey } from './list-dom';
import {
  applySelectionPresentation,
  batchSelectedAttribute,
  liveMovableItems,
  orderedItemElements,
  orderedSelectedItemElements,
  resolveCandidate,
} from './selection';

// Mirrors the root: the nearest list element that belongs to this root,
// with the Box list's <ul> as its rows container when it has one.
function topologyFor(root:HTMLElement):ListTopology {
  const rootSelector = '[data-controller~="sortable-lists"]';
  return {
    rootElement: root,
    owns: (element) => element.closest(rootSelector) === root,
    ownerList: (element) => {
      const list = element.closest<HTMLElement>('[data-controller~="sortable-lists--list"]');
      if (list?.closest(rootSelector) !== root) {
        return null;
      }
      const identity = {
        type: list.getAttribute('data-sortable-lists--list-type-value') ?? '',
        id: list.getAttribute('data-sortable-lists--list-id-value'),
      };
      return {
        element: list,
        identity,
        listData: sortableListData({ type: identity.type, listId: identity.id }),
        rowsContainer: list.querySelector<HTMLElement>(':scope > ul') ?? list,
      };
    },
  };
}

describe('sortable-lists selection adapter', () => {
  let root:HTMLElement;

  // Two lists. Sprint 7 holds movable 1 and 2, a truncation marker, and
  // movable 3. Sprint 8 holds movable 4 and non-movable 5.
  beforeEach(() => {
    root = document.createElement('div');
    root.setAttribute('data-controller', 'sortable-lists');
    root.innerHTML = `
      <div data-controller="sortable-lists--list"
           data-sortable-lists--list-type-value="sprint"
           data-sortable-lists--list-id-value="7">
        <ul>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="1" data-sortable-lists--item-type-value="work_package"><span>one</span></li>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="2" data-sortable-lists--item-type-value="work_package"></li>
          <li data-sortable-lists-prev-item-id="2" data-sortable-lists-omitted-count="9"></li>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="3" data-sortable-lists--item-type-value="work_package"></li>
        </ul>
      </div>
      <div data-controller="sortable-lists--list"
           data-sortable-lists--list-type-value="sprint"
           data-sortable-lists--list-id-value="8">
        <ul>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="4" data-sortable-lists--item-type-value="work_package"></li>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="5" data-sortable-lists--item-type-value="work_package"
              data-sortable-lists--item-mobility-value="fixed"></li>
        </ul>
      </div>
    `;
    document.body.appendChild(root);
  });

  afterEach(() => {
    root.remove();
  });

  // The rows container the host resolves in production; supplied directly
  // here because this spec drives the adapter without one.

  const itemFor = (id:string) => root.querySelector<HTMLElement>(`[data-sortable-lists--item-id-value="${id}"]`)!;
  const candidateFor = (id:string) => resolveCandidate(topologyFor(root), itemFor(id))!;

  // A trailing item in sprint 7 that hosts a list of its own, the nested
  // topology a section-and-fields consumer renders.
  const appendNestedList = () => {
    const section = document.createElement('li');
    section.setAttribute('data-controller', 'sortable-lists--item');
    section.setAttribute('data-sortable-lists--item-id-value', '6');
    section.setAttribute('data-sortable-lists--item-type-value', 'section');
    section.innerHTML = `
      <div data-controller="sortable-lists--list"
           data-sortable-lists--list-type-value="section"
           data-sortable-lists--list-id-value="6">
        <ul>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="60" data-sortable-lists--item-type-value="field"></li>
        </ul>
      </div>
    `;
    root.querySelector('ul')!.appendChild(section);
  };

  it('resolves a candidate from a descendant of the item', () => {
    const candidate = resolveCandidate(topologyFor(root), itemFor('1').querySelector('span'));

    expect(candidate).toEqual({
      type: 'work_package',
      itemElement: itemFor('1'),
      focusHost: itemFor('1'),
      id: '1',
      listKey: listKey({ type: 'sprint', id: '7' }),
      movable: true,
    });
  });

  it('keys the list by its type and id, not its DOM id', () => {
    itemFor('1').closest('[data-controller~="sortable-lists--list"]')!.id = 'inbox_project_4';

    expect(candidateFor('1').listKey).toBe(listKey({ type: 'sprint', id: '7' }));
  });

  // The focus host is also the boundary the interactive-descendant check
  // stops at, so a focusable host does not disqualify its own card.
  it('reports the focus target as the focus host when there is one', () => {
    const card = document.createElement('div');
    card.setAttribute('data-sortable-lists--item-target', 'focus');
    card.tabIndex = 0;
    itemFor('2').appendChild(card);

    expect(resolveCandidate(topologyFor(root), card)!.focusHost).toBe(card);
  });

  it('does not take a nested item\'s focus target as the focus host', () => {
    appendNestedList();
    itemFor('60').setAttribute('data-sortable-lists--item-target', 'focus');

    expect(candidateFor('6').focusHost).toBe(itemFor('6'));
  });

  it('resolves a non-movable candidate', () => {
    expect(candidateFor('5').movable).toBe(false);
  });

  it('does not resolve a truncation marker as a candidate', () => {
    const marker = root.querySelector<HTMLElement>('[data-sortable-lists-prev-item-id]')!;

    expect(resolveCandidate(topologyFor(root), marker)).toBeNull();
  });

  it('does not resolve anything outside the root', () => {
    expect(resolveCandidate(topologyFor(root), document.body)).toBeNull();
  });

  it('refuses to resolve a candidate that declares no type', () => {
    const untyped = document.createElement('li');
    untyped.setAttribute('data-controller', 'sortable-lists--item');
    untyped.setAttribute('data-sortable-lists--item-id-value', '99');
    root.querySelector('ul')!.appendChild(untyped);

    expect(resolveCandidate(topologyFor(root), untyped)).toBeNull();
  });

  // An independently nested root is an ownership boundary.
  it('does not own items belonging to a nested root', () => {
    const nested = document.createElement('div');
    nested.setAttribute('data-controller', 'sortable-lists');
    nested.innerHTML = `
      <div data-controller="sortable-lists--list" data-sortable-lists--list-id-value="9">
        <ul>
          <li data-controller="sortable-lists--item"
              data-sortable-lists--item-id-value="90"
              data-sortable-lists--item-type-value="work_package"></li>
        </ul>
      </div>
    `;
    root.appendChild(nested);
    const inner = nested.querySelector<HTMLElement>('[data-sortable-lists--item-id-value="90"]')!;

    expect(resolveCandidate(topologyFor(root), inner)).toBeNull();
    expect(orderedItemElements(root)).not.toContain(inner);
  });

  it('returns selected item elements in live document order', () => {
    const keys = new Set(['4', '1', '3'].map((id) => selectionKey({ type: 'work_package', id })));

    expect(orderedSelectedItemElements(root, keys)).toEqual([itemFor('1'), itemFor('3'), itemFor('4')]);
  });

  it('lists only live movable items', () => {
    expect(liveMovableItems(root).map((item) => item.id)).toEqual(['1', '2', '3', '4']);
  });


  it('writes only changed members during an incremental render', () => {
    const key1 = selectionKey({ type: 'work_package', id: '1' });
    const key3 = selectionKey({ type: 'work_package', id: '3' });
    applySelectionPresentation(root, new Set([key1]), 'selected-description');
    const observer = new MutationObserver(vi.fn());
    observer.observe(root, { attributes: true, subtree: true });

    applySelectionPresentation(root, new Set([key1, key3]), 'selected-description', new Set([key3]));

    const mutations = observer.takeRecords();
    observer.disconnect();
    expect(mutations.length).toBeGreaterThan(0);
    expect(mutations.every((mutation) => mutation.target === itemFor('3'))).toBe(true);
    expect(itemFor('3').hasAttribute(batchSelectedAttribute)).toBe(true);
    expect(itemFor('3').getAttribute('aria-describedby')).toBe('selected-description');
  });

  it('does not traverse or write when no membership changed', () => {
    const query = vi.spyOn(root, 'querySelectorAll');
    applySelectionPresentation(root, new Set(), 'selected-description', new Set());
    expect(query).not.toHaveBeenCalled();
    query.mockRestore();
  });

  it('removes only its description when a changed member is deselected', () => {
    const key = selectionKey({ type: 'work_package', id: '1' });
    itemFor('1').setAttribute('aria-describedby', 'own-description');
    applySelectionPresentation(root, new Set([key]), 'selected-description');

    applySelectionPresentation(root, new Set(), 'selected-description', new Set([key]));

    expect(itemFor('1').hasAttribute(batchSelectedAttribute)).toBe(false);
    expect(itemFor('1').getAttribute('aria-describedby')).toBe('own-description');
  });

  it('filters changed keys by type and leaves nested roots alone', () => {
    const section = itemFor('1').cloneNode(true) as HTMLElement;
    section.setAttribute('data-sortable-lists--item-type-value', 'section');
    root.append(section);
    const nested = root.cloneNode(true) as HTMLElement;
    root.append(nested);
    const key = selectionKey({ type: 'work_package', id: '1' });

    applySelectionPresentation(root, new Set([key]), 'selected-description', new Set([key]));

    expect(itemFor('1').hasAttribute(batchSelectedAttribute)).toBe(true);
    expect(section.hasAttribute(batchSelectedAttribute)).toBe(false);
    expect(nested.querySelectorAll('[data-batch-selected]')).toHaveLength(0);
  });

  it('applies and clears the batch presentation', () => {
    applySelectionPresentation(root, new Set([selectionKey({ type: 'work_package', id: '1' }), selectionKey({ type: 'work_package', id: '3' })]), 'selected-description');

    expect(itemFor('1').hasAttribute(batchSelectedAttribute)).toBe(true);
    expect(itemFor('2').hasAttribute(batchSelectedAttribute)).toBe(false);

    applySelectionPresentation(root, new Set([selectionKey({ type: 'work_package', id: '3' })]), 'selected-description');

    expect(itemFor('1').hasAttribute(batchSelectedAttribute)).toBe(false);
    expect(itemFor('3').hasAttribute(batchSelectedAttribute)).toBe(true);
  });

  // An accessible description is computed from the focused element's own
  // `aria-describedby` and never inherited from an ancestor, so it belongs on
  // the focus host: in Backlogs the row never receives focus, the card does.
  it('describes a selected card and stops describing a deselected one', () => {
    const focusHost = document.createElement('div');
    focusHost.setAttribute('data-sortable-lists--item-target', 'focus');
    itemFor('1').appendChild(focusHost);

    applySelectionPresentation(root, new Set([selectionKey({ type: 'work_package', id: '1' })]), 'selected-description');

    expect(focusHost.getAttribute('aria-describedby')).toBe('selected-description');
    expect(itemFor('1').hasAttribute('aria-describedby')).toBe(false);

    applySelectionPresentation(root, new Set(), 'selected-description');

    expect(focusHost.hasAttribute('aria-describedby')).toBe(false);
  });

  // Nothing prunes duplicates on read, so a repeated apply is the only thing
  // that catches a regression of the write-time de-duplication.
  it('describes the outer item, not a nested item\'s focus target', () => {
    appendNestedList();
    const nestedTarget = itemFor('60');
    nestedTarget.setAttribute('data-sortable-lists--item-target', 'focus');

    applySelectionPresentation(root, new Set([selectionKey({ type: 'section', id: '6' })]), 'selected-description');

    expect(itemFor('6').getAttribute('aria-describedby')).toBe('selected-description');
    expect(nestedTarget.hasAttribute('aria-describedby')).toBe(false);
  });

  it('does not accumulate duplicate description tokens on repeated apply', () => {
    applySelectionPresentation(root, new Set([selectionKey({ type: 'work_package', id: '1' })]), 'selected-description');
    applySelectionPresentation(root, new Set([selectionKey({ type: 'work_package', id: '1' })]), 'selected-description');

    expect(itemFor('1').getAttribute('aria-describedby')).toBe('selected-description');
  });

  it('leaves a description the card already had', () => {
    itemFor('1').setAttribute('aria-describedby', 'card-hint');

    applySelectionPresentation(root, new Set([selectionKey({ type: 'work_package', id: '1' })]), 'selected-description');
    expect(itemFor('1').getAttribute('aria-describedby')).toBe('card-hint selected-description');

    applySelectionPresentation(root, new Set(), 'selected-description');
    expect(itemFor('1').getAttribute('aria-describedby')).toBe('card-hint');
  });

  it('skips the description wiring when no description element is configured', () => {
    applySelectionPresentation(root, new Set([selectionKey({ type: 'work_package', id: '1' })]), '');

    expect(itemFor('1').hasAttribute('aria-describedby')).toBe(false);
    expect(itemFor('1').hasAttribute(batchSelectedAttribute)).toBe(true);
  });

});
