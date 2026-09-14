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
import {
  applySelectionPresentation,
  batchSelectedAttribute,
  listBoundaryItem,
  liveOrderableItems,
  liveOrderableListItems,
  neighbourItem,
  orderedItemElements,
  orderedSelectedItems,
  resolveCandidate,
  resolveRangeItems,
} from './selection';

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
  const rowsContainerFor = (item:HTMLElement) => {
    const list = item.closest<HTMLElement>('[data-controller~="sortable-lists--list"]');
    return list ? (list.querySelector<HTMLElement>(':scope > ul') ?? list) : null;
  };

  const itemFor = (id:string) => root.querySelector<HTMLElement>(`[data-sortable-lists--item-id-value="${id}"]`)!;
  const candidateFor = (id:string) => resolveCandidate(root, itemFor(id))!;

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
    const candidate = resolveCandidate(root, itemFor('1').querySelector('span'));

    expect(candidate).toEqual({
      type: 'work_package',
      itemElement: itemFor('1'),
      focusHost: itemFor('1'),
      id: '1',
      listKey: 'sprint:7',
      orderable: true,
    });
  });

  it('keys the list by its type and id, not its DOM id', () => {
    itemFor('1').closest('[data-controller~="sortable-lists--list"]')!.id = 'inbox_project_4';

    expect(candidateFor('1').listKey).toBe('sprint:7');
  });

  // The focus host is also the boundary the interactive-descendant check
  // stops at, so a focusable host does not disqualify its own card.
  it('reports the focus target as the focus host when there is one', () => {
    const card = document.createElement('div');
    card.setAttribute('data-sortable-lists--item-target', 'focus');
    card.tabIndex = 0;
    itemFor('2').appendChild(card);

    expect(resolveCandidate(root, card)!.focusHost).toBe(card);
  });

  it('does not take a nested item\'s focus target as the focus host', () => {
    appendNestedList();
    itemFor('60').setAttribute('data-sortable-lists--item-target', 'focus');

    expect(candidateFor('6').focusHost).toBe(itemFor('6'));
  });

  it('resolves a non-movable candidate', () => {
    expect(candidateFor('5').orderable).toBe(false);
  });

  it('does not resolve a truncation marker as a candidate', () => {
    const marker = root.querySelector<HTMLElement>('[data-sortable-lists-prev-item-id]')!;

    expect(resolveCandidate(root, marker)).toBeNull();
  });

  it('does not resolve anything outside the root', () => {
    expect(resolveCandidate(root, document.body)).toBeNull();
  });

  it('refuses to resolve a candidate that declares no type', () => {
    const untyped = document.createElement('li');
    untyped.setAttribute('data-controller', 'sortable-lists--item');
    untyped.setAttribute('data-sortable-lists--item-id-value', '99');
    root.querySelector('ul')!.appendChild(untyped);

    expect(resolveCandidate(root, untyped)).toBeNull();
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

    expect(resolveCandidate(root, inner)).toBeNull();
    expect(orderedItemElements(root)).not.toContain(inner);
  });

  it('orders selected items by live document order across lists', () => {
    const keys = new Set(['4', '1', '3'].map((id) => selectionKey({ type: 'work_package', id })));

    expect(orderedSelectedItems(root, keys).map((item) => item.id)).toEqual(['1', '3', '4']);
  });

  it('lists only live orderable items', () => {
    expect(liveOrderableItems(root).map((item) => item.id)).toEqual(['1', '2', '3', '4']);
  });

  it('resolves an ascending range within one list', () => {
    const anchor = { type: 'work_package', id: '1', listKey: 'sprint:7' };

    expect(resolveRangeItems(root, anchor, candidateFor('2'), rowsContainerFor(itemFor('2')))).toEqual({ ok: true, items: [{ type: 'work_package', id: '1' }, { type: 'work_package', id: '2' }] });
  });

  it('resolves a descending range within one list', () => {
    const anchor = { type: 'work_package', id: '2', listKey: 'sprint:7' };

    expect(resolveRangeItems(root, anchor, candidateFor('1'), rowsContainerFor(itemFor('1')))).toEqual({ ok: true, items: [{ type: 'work_package', id: '1' }, { type: 'work_package', id: '2' }] });
  });

  it('rejects a range that would cross a truncation marker', () => {
    const anchor = { type: 'work_package', id: '2', listKey: 'sprint:7' };

    expect(resolveRangeItems(root, anchor, candidateFor('3'), rowsContainerFor(itemFor('3')))).toEqual({ ok: false, reason: 'unavailable' });
  });

  it('rejects a range that would cross a list boundary', () => {
    const anchor = { type: 'work_package', id: '3', listKey: 'sprint:7' };

    expect(resolveRangeItems(root, anchor, candidateFor('4'), rowsContainerFor(itemFor('4')))).toEqual({ ok: false, reason: 'crossList' });
  });

  it('does not take a same-id item of another type for the anchor', () => {
    const decoy = document.createElement('li');
    decoy.setAttribute('data-controller', 'sortable-lists--item');
    decoy.setAttribute('data-sortable-lists--item-id-value', '1');
    decoy.setAttribute('data-sortable-lists--item-type-value', 'decoy');
    root.querySelector('ul')!.prepend(decoy);
    const anchor = { type: 'work_package', id: '1', listKey: 'sprint:7' };
    const candidate = candidateFor('2');

    expect(resolveRangeItems(root, anchor, candidate, rowsContainerFor(candidate.itemElement))).toEqual({ ok: true, items: [{ type: 'work_package', id: '1' }, { type: 'work_package', id: '2' }] });
  });

  // A structural row holding only a nested list has no item of its own; the
  // nested list's first field must not be mistaken for one.
  it('rejects a range across a row that only hosts a nested list', () => {
    const hostRow = document.createElement('li');
    hostRow.innerHTML = `
      <div data-controller="sortable-lists--list"
           data-sortable-lists--list-type-value="section"
           data-sortable-lists--list-id-value="6">
        <ul>
          <li data-controller="sortable-lists--item" data-sortable-lists--item-id-value="60" data-sortable-lists--item-type-value="field"></li>
        </ul>
      </div>
    `;
    itemFor('1').after(hostRow);
    const anchor = { type: 'work_package', id: '1', listKey: 'sprint:7' };
    const candidate = candidateFor('2');

    expect(resolveRangeItems(root, anchor, candidate, rowsContainerFor(candidate.itemElement))).toEqual({ ok: false, reason: 'unavailable' });
  });

  it('rejects a range whose anchor id was never a row in this list', () => {
    const anchor = { type: 'work_package', id: '99', listKey: 'sprint:7' };

    expect(resolveRangeItems(root, anchor, candidateFor('2'), rowsContainerFor(itemFor('2')))).toEqual({ ok: false, reason: 'unavailable' });
  });

  // Refused, not trimmed to the movable cards — and with its own reason,
  // since expanding the list can never resolve a locked card.
  it('refuses a range that would include a non-movable card', () => {
    const anchor = { type: 'work_package', id: '4', listKey: 'sprint:8' };

    expect(resolveRangeItems(root, anchor, candidateFor('5'), rowsContainerFor(itemFor('5')))).toEqual({ ok: false, reason: 'locked' });
  });

  // list-dom's contract lets a row wrap its item instead of being it.
  it('resolves a range across rows that wrap their item element', () => {
    const wrappingRoot = document.createElement('div');
    wrappingRoot.setAttribute('data-controller', 'sortable-lists');
    wrappingRoot.innerHTML = `
      <div data-controller="sortable-lists--list"
           data-sortable-lists--list-type-value="sprint"
           data-sortable-lists--list-id-value="20">
        <ul>
          <li><div data-controller="sortable-lists--item" data-sortable-lists--item-id-value="20" data-sortable-lists--item-type-value="work_package"></div></li>
          <li><div data-controller="sortable-lists--item" data-sortable-lists--item-id-value="21" data-sortable-lists--item-type-value="work_package"></div></li>
          <li><div data-controller="sortable-lists--item" data-sortable-lists--item-id-value="22" data-sortable-lists--item-type-value="work_package"></div></li>
        </ul>
      </div>
    `;
    document.body.appendChild(wrappingRoot);

    try {
      const wrappedItemFor = (id:string) => wrappingRoot.querySelector<HTMLElement>(
        `[data-sortable-lists--item-id-value="${id}"]`,
      )!;
      const anchor = { type: 'work_package', id: '20', listKey: 'sprint:20' };
      const candidate = resolveCandidate(wrappingRoot, wrappedItemFor('22'))!;

      expect(resolveRangeItems(wrappingRoot, anchor, candidate, rowsContainerFor(candidate.itemElement))).toEqual({ ok: true, items: [{ type: 'work_package', id: '20' }, { type: 'work_package', id: '21' }, { type: 'work_package', id: '22' }] });
    } finally {
      wrappingRoot.remove();
    }
  });

  // A candidate whose item lives outside the list's rows container has no
  // row to find there.
  it('rejects a range when the candidate item sits outside the rows container', () => {
    const list = root.querySelector<HTMLElement>('[data-sortable-lists--list-id-value="7"]')!;
    const strayItem = document.createElement('div');
    strayItem.setAttribute('data-controller', 'sortable-lists--item');
    strayItem.setAttribute('data-sortable-lists--item-id-value', '30');
    strayItem.setAttribute('data-sortable-lists--item-type-value', 'work_package');
    list.appendChild(strayItem);

    const anchor = { type: 'work_package', id: '1', listKey: 'sprint:7' };
    const candidate = resolveCandidate(root, strayItem)!;

    expect(resolveRangeItems(root, anchor, candidate, rowsContainerFor(candidate.itemElement))).toEqual({ ok: false, reason: 'unavailable' });
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

  it('finds the next and previous item within one list', () => {
    expect(neighbourItem(root, itemFor('1'), 1)).toBe(itemFor('2'));
    expect(neighbourItem(root, itemFor('2'), -1)).toBe(itemFor('1'));
  });

  it('does not step across a list boundary', () => {
    expect(neighbourItem(root, itemFor('3'), 1)).toBeNull();
  });

  // Not filtered by movability, unlike listBoundaryItem below.
  it('steps onto a non-movable card with the arrow', () => {
    expect(neighbourItem(root, itemFor('4'), 1)).toBe(itemFor('5'));
  });

  it('finds the first and last item of the containing list', () => {
    expect(listBoundaryItem(root, itemFor('2'), 'first')).toBe(itemFor('1'));
    expect(listBoundaryItem(root, itemFor('2'), 'last')).toBe(itemFor('3'));
  });

  // Sprint 8 holds movable 4 and non-movable 5 (see the fixture comment
  // above): the trailing non-movable card must not become the End target.
  it('skips a non-movable card at the list boundary', () => {
    expect(listBoundaryItem(root, itemFor('4'), 'last')).toBe(itemFor('4'));
  });

  // A section item hosting its own list is an ownership boundary too.
  it('does not step into a list nested inside the list', () => {
    appendNestedList();

    expect(neighbourItem(root, itemFor('6'), 1)).toBeNull();
  });

  it('confines list-scoped select-all to the items the list itself owns', () => {
    appendNestedList();

    expect(liveOrderableListItems(root, itemFor('1')).map((item) => item.id)).toEqual(['1', '2', '3', '6']);
  });

  it('returns null when no movable card remains in the list', () => {
    itemFor('4').setAttribute('data-sortable-lists--item-mobility-value', 'fixed');

    expect(listBoundaryItem(root, itemFor('4'), 'first')).toBeNull();
    expect(listBoundaryItem(root, itemFor('4'), 'last')).toBeNull();
  });
});
