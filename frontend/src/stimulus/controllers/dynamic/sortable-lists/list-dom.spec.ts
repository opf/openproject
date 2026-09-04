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

import {
  captureRowPositions,
  reorderRows,
  resolveDirectionalPreviousItemId,
  resolveMoveAvailability,
  resolveListAppendPreviousItemId,
  resolveItemPosition,
  resolveItemLabel,
  resolveItemType,
  restoreRowPositions,
  rowOf,
  rowsRemainAt,
} from './list-dom';

describe('sortable lists DOM helpers', () => {
  function itemRow(id:string):HTMLLIElement {
    const row = document.createElement('li');
    const item = document.createElement('article');

    row.setAttribute('data-sortable-lists--item-id-value', id);
    row.appendChild(item);

    return row;
  }

  function divItemRow(id:string):HTMLDivElement {
    const row = document.createElement('div');
    row.setAttribute('data-sortable-lists--item-id-value', id);
    return row;
  }

  function showMoreRow(previousItemId = 'hidden-item'):HTMLLIElement {
    const row = document.createElement('li');

    row.setAttribute('data-sortable-lists-prev-item-id', previousItemId);

    return row;
  }

  function listElement():HTMLUListElement {
    const list = document.createElement('ul');

    list.setAttribute('data-sortable-lists-target', 'list');

    return list;
  }

  function itemIdOrder(list:HTMLElement):string[] {
    return Array.from(list.querySelectorAll('[data-sortable-lists--item-id-value]'))
      .map((element) => element.getAttribute('data-sortable-lists--item-id-value')!);
  }

  describe('resolveListAppendPreviousItemId', () => {
    it('returns the last item in a list while skipping the source and truncation marker rows', () => {
      const list = listElement();

      list.append(itemRow('1'), showMoreRow(), itemRow('2'), itemRow('3'));

      expect(resolveListAppendPreviousItemId({ sourceItemId: '3', rowsContainer: list })).toEqual('2');
    });

    it('returns null when the list has no other items', () => {
      const list = listElement();

      list.append(itemRow('1'));

      expect(resolveListAppendPreviousItemId({ sourceItemId: '1', rowsContainer: list })).toBeNull();
    });

    it('returns null for an empty list nested inside an outer item, not the outer item\'s id', () => {
      // Nested topology: a section item hosting its own field list. The only
      // row is a non-item placeholder (no item id, no prev-item-id marker),
      // and every ancestor up to the root belongs to the outer (section)
      // item/list pair. Regression: resolving a "previous item" here must not
      // climb past the list boundary and match the outer section's item id.
      const outerItem = divItemRow('outer-section');
      const list = listElement();
      const placeholder = document.createElement('li');

      list.append(placeholder);
      outerItem.append(list);

      expect(resolveListAppendPreviousItemId({ sourceItemId: 'field-1', rowsContainer: list })).toBeNull();
    });
  });

  describe('reorderRows', () => {
    it('moves a row to sit immediately after the previous item anchor', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      reorderRows({ rows: [one], rowsContainer: list, previousItemId: '2' });

      expect(itemIdOrder(list)).toEqual(['2', '1', '3']);
    });

    it('moves a row to the top of the list before the first existing row', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      reorderRows({ rows: [three], rowsContainer: list, previousItemId: null });

      expect(itemIdOrder(list)).toEqual(['3', '1', '2']);
    });

    it('reorders rows that are neither <ul> nor <li> under any container element', () => {
      const rowsContainer = document.createElement('div');
      const [one, two, three] = ['1', '2', '3'].map(divItemRow);

      rowsContainer.append(one, two, three);
      reorderRows({ rows: [three], rowsContainer, previousItemId: '1' });

      expect(itemIdOrder(rowsContainer)).toEqual(['1', '3', '2']);
    });

    it('resolves the row that holds a nested element via rowOf', () => {
      const rowsContainer = document.createElement('ul');
      const row = itemRow('9');
      const inner = row.querySelector<HTMLElement>('article')!;

      rowsContainer.append(row);

      expect(rowOf(rowsContainer, inner)).toBe(row);
      expect(rowOf(rowsContainer, row)).toBe(row);
      expect(rowOf(rowsContainer, document.createElement('div'))).toBeNull();
    });

    it('inserts a moved group after the anchor preserving their order', () => {
      const list = listElement();
      const [one, two, three, four] = ['1', '2', '3', '4'].map(itemRow);

      list.append(one, two, three, four);
      reorderRows({ rows: [three, four], rowsContainer: list, previousItemId: '1' });

      expect(itemIdOrder(list)).toEqual(['1', '3', '4', '2']);
    });

    it('anchors on the outer list row, not a nested item with a colliding id', () => {
      // Section and custom-field ids come from different tables, so a field
      // nested inside section "1" may carry the same id as section "2".
      // Resolving section "2" as the anchor must match the outer row, never
      // descend into the nested field list.
      const list = listElement();
      const [sectionOne, sectionTwo, sectionThree] = ['1', '2', '3'].map(divItemRow);
      const nestedList = listElement();
      const collidingField = itemRow('2');

      nestedList.append(collidingField);
      sectionOne.append(nestedList);
      list.append(sectionOne, sectionTwo, sectionThree);

      reorderRows({ rows: [sectionThree], rowsContainer: list, previousItemId: '2' });

      expect(Array.from(list.children)).toEqual([sectionOne, sectionTwo, sectionThree]);
    });

    it('anchors on a truncation marker row when the previous item is hidden', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);
      const marker = showMoreRow('hidden');

      list.append(three, one, marker, two);
      reorderRows({ rows: [three], rowsContainer: list, previousItemId: 'hidden' });

      expect(three.previousElementSibling).toBe(marker);
      expect(itemIdOrder(list)).toEqual(['1', '3', '2']);
    });
  });

  describe('captureRowPositions / restoreRowPositions', () => {
    // restoreRowPositions guards on the captured parent being connected, so these
    // lists are mounted in the document to reflect the live frame they run against.
    afterEach(() => {
      document.body.replaceChildren();
    });

    it('restores a row to its original position after an optimistic move', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      document.body.append(list);
      const snapshot = captureRowPositions([three]);

      reorderRows({ rows: [three], rowsContainer: list, previousItemId: null });
      expect(itemIdOrder(list)).toEqual(['3', '1', '2']);

      restoreRowPositions(snapshot);
      expect(itemIdOrder(list)).toEqual(['1', '2', '3']);
    });

    it('restores a multi-row group to its original order', () => {
      const list = listElement();
      const [one, two, three, four] = ['1', '2', '3', '4'].map(itemRow);

      list.append(one, two, three, four);
      document.body.append(list);
      const snapshot = captureRowPositions([two, three]);

      reorderRows({ rows: [two, three], rowsContainer: list, previousItemId: '4' });
      expect(itemIdOrder(list)).toEqual(['1', '4', '2', '3']);

      restoreRowPositions(snapshot);
      expect(itemIdOrder(list)).toEqual(['1', '2', '3', '4']);
    });

    it('falls back to appending when the captured next sibling is stale', () => {
      const list = listElement();
      const [one, two] = ['1', '2'].map(itemRow);

      list.append(one, two);
      document.body.append(list);
      const snapshot = captureRowPositions([one]);
      two.remove();

      expect(() => restoreRowPositions(snapshot)).not.toThrow();
      expect(itemIdOrder(list)).toEqual(['1']);
    });

    it('does not restore a row into a captured parent that has detached', () => {
      const list = listElement();
      const destination = listElement();
      const [one, two] = ['1', '2'].map(itemRow);

      list.append(one, two);
      document.body.append(list, destination);
      const snapshot = captureRowPositions([one]);

      // Optimistic move relocates the row into a live destination list.
      destination.append(one);
      // A mid-flight list-refresh morph detaches the original list.
      list.remove();

      restoreRowPositions(snapshot);

      // The row is not pulled back into the detached list; it stays live.
      expect(one.isConnected).toBe(true);
      expect(itemIdOrder(destination)).toEqual(['1']);
    });
  });

  describe('rowsRemainAt', () => {
    afterEach(() => {
      document.body.replaceChildren();
    });

    it('is true while rows still sit at their captured placement', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      document.body.append(list);

      reorderRows({ rows: [three], rowsContainer: list, previousItemId: null });
      const optimistic = captureRowPositions([three]);

      expect(rowsRemainAt(optimistic)).toBe(true);
    });

    it('is true when every row of a multi-row group remains at its captured placement', () => {
      const list = listElement();
      const [one, two, three, four] = ['1', '2', '3', '4'].map(itemRow);

      list.append(one, two, three, four);
      document.body.append(list);

      reorderRows({ rows: [two, three], rowsContainer: list, previousItemId: '4' });
      const optimistic = captureRowPositions([two, three]);

      expect(rowsRemainAt(optimistic)).toBe(true);
    });

    it('is false once a captured row has been removed', () => {
      const list = listElement();
      const [one, two] = ['1', '2'].map(itemRow);

      list.append(one, two);
      document.body.append(list);
      const optimistic = captureRowPositions([two]);

      // A morph removing the row (e.g. it moved lists server-side) must not be
      // undone by a later rollback re-inserting the detached node.
      two.remove();

      expect(rowsRemainAt(optimistic)).toBe(false);
    });

    it('is false once a captured row has been repositioned', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      document.body.append(list);
      const optimistic = captureRowPositions([one]);

      list.append(one);

      expect(rowsRemainAt(optimistic)).toBe(false);
    });

    it('is false when a sibling was inserted at the captured next-sibling slot', () => {
      const list = listElement();
      const [one, two] = ['1', '2'].map(itemRow);

      list.append(one, two);
      document.body.append(list);
      const optimistic = captureRowPositions([one]);

      // Deliberately conservative: any churn around the row counts as a morph
      // owning the region, so the rollback yields to the fresher server state.
      one.after(itemRow('99'));

      expect(rowsRemainAt(optimistic)).toBe(false);
    });

    it('checks every row of a multi-row group', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      document.body.append(list);
      const optimistic = captureRowPositions([one, two]);

      list.append(one);

      expect(rowsRemainAt(optimistic)).toBe(false);
    });
  });
});

describe('directional move helpers', () => {
  function container(ids:string[]):HTMLElement {
    const ul = document.createElement('ul');
    ul.innerHTML = ids.map((id) => `<li data-sortable-lists--item-id-value="${id}"></li>`).join('');
    return ul;
  }
  const itemAt = (ul:HTMLElement, index:number) => ul.children[index] as HTMLElement;

  it('reports per-direction availability', () => {
    const ul = container(['1', '2', '3']);
    expect(resolveMoveAvailability({ itemElement: itemAt(ul, 0), rowsContainer: ul }))
      .toEqual({ top: false, up: false, down: true, bottom: true });
    expect(resolveMoveAvailability({ itemElement: itemAt(ul, 1), rowsContainer: ul }))
      .toEqual({ top: true, up: true, down: true, bottom: true });
    expect(resolveMoveAvailability({ itemElement: itemAt(ul, 2), rowsContainer: ul }))
      .toEqual({ top: true, up: true, down: false, bottom: false });
  });

  it('returns null availability when the item is not in the container', () => {
    const ul = container(['1']);
    const stray = document.createElement('li');
    expect(resolveMoveAvailability({ itemElement: stray, rowsContainer: ul })).toBeNull();
  });

  it('maps each direction to a previous item id', () => {
    const ul = container(['1', '2', '3', '4']);
    const at = (i:number) => ({ itemElement: itemAt(ul, i), rowsContainer: ul });
    // item '3' (index 2)
    expect(resolveDirectionalPreviousItemId({ ...at(2), direction: 'top' })).toBeNull();
    expect(resolveDirectionalPreviousItemId({ ...at(2), direction: 'up' })).toBe('1');
    expect(resolveDirectionalPreviousItemId({ ...at(2), direction: 'down' })).toBe('4');
    expect(resolveDirectionalPreviousItemId({ ...at(2), direction: 'bottom' })).toBe('4');
    // second item moving up lands at the top
    expect(resolveDirectionalPreviousItemId({ ...at(1), direction: 'up' })).toBeNull();
  });

  it('returns undefined when the direction is unavailable', () => {
    const ul = container(['1', '2']);
    const first = { itemElement: itemAt(ul, 0), rowsContainer: ul };
    const last = { itemElement: itemAt(ul, 1), rowsContainer: ul };
    expect(resolveDirectionalPreviousItemId({ ...first, direction: 'top' })).toBeUndefined();
    expect(resolveDirectionalPreviousItemId({ ...first, direction: 'up' })).toBeUndefined();
    expect(resolveDirectionalPreviousItemId({ ...last, direction: 'down' })).toBeUndefined();
    expect(resolveDirectionalPreviousItemId({ ...last, direction: 'bottom' })).toBeUndefined();
  });

  describe('across a truncation marker (sparse list: head + hidden block + tail)', () => {
    // Rows: h1, h2, <marker prev=last-hidden>, t1, t2. The marker stands in for
    // a block of hidden work packages the client cannot address one item at a
    // time.
    function truncatedContainer():HTMLElement {
      const ul = document.createElement('ul');
      ul.innerHTML = [
        '<li data-sortable-lists--item-id-value="h1"></li>',
        '<li data-sortable-lists--item-id-value="h2"></li>',
        '<li data-sortable-lists-prev-item-id="last-hidden"></li>',
        '<li data-sortable-lists--item-id-value="t1"></li>',
        '<li data-sortable-lists--item-id-value="t2"></li>',
      ].join('');
      return ul;
    }
    const byId = (ul:HTMLElement, id:string) =>
      ul.querySelector<HTMLElement>(`[data-sortable-lists--item-id-value="${id}"]`)!;
    const at = (ul:HTMLElement, id:string) => ({ itemElement: byId(ul, id), rowsContainer: ul });

    it('disables a one-step move that would cross the hidden block', () => {
      const ul = truncatedContainer();
      // "down" from the last head item and "up" from the first tail item would
      // jump the whole hidden block, so they are unavailable.
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'h2'), direction: 'down' })).toBeUndefined();
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 't1'), direction: 'up' })).toBeUndefined();
    });

    it('keeps one-step moves within a visible chunk', () => {
      const ul = truncatedContainer();
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'h1'), direction: 'down' })).toBe('h2');
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'h2'), direction: 'up' })).toBeNull();
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 't1'), direction: 'down' })).toBe('t2');
    });

    it('anchors a tail item stepping up onto the hidden block via the marker id', () => {
      const ul = truncatedContainer();
      // t2 up one slot lands just after the hidden block, before t1.
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 't2'), direction: 'up' })).toBe('last-hidden');
    });

    it('still allows the addressable extremes across the block', () => {
      const ul = truncatedContainer();
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'h1'), direction: 'top' })).toBeUndefined();
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'h1'), direction: 'bottom' })).toBe('t2');
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 't2'), direction: 'top' })).toBeNull();
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 't2'), direction: 'bottom' })).toBeUndefined();
    });
  });

  describe('across an unannotated non-item row (a divider between items)', () => {
    // Rows: a, b, <divider with no prev-item-id>, c, d. Unlike a truncation
    // marker the divider gives no anchor, so one-step moves cannot cross or
    // land next to it; only the extremes stay available.
    function dividedContainer():HTMLElement {
      const ul = document.createElement('ul');
      ul.innerHTML = [
        '<li data-sortable-lists--item-id-value="a"></li>',
        '<li data-sortable-lists--item-id-value="b"></li>',
        '<li class="divider"></li>',
        '<li data-sortable-lists--item-id-value="c"></li>',
        '<li data-sortable-lists--item-id-value="d"></li>',
      ].join('');
      return ul;
    }
    const byId = (ul:HTMLElement, id:string) =>
      ul.querySelector<HTMLElement>(`[data-sortable-lists--item-id-value="${id}"]`)!;
    const at = (ul:HTMLElement, id:string) => ({ itemElement: byId(ul, id), rowsContainer: ul });

    it('disables one-step moves whose neighbouring row is the divider', () => {
      const ul = dividedContainer();
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'b'), direction: 'down' })).toBeUndefined();
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'c'), direction: 'up' })).toBeUndefined();
    });

    it('disables a one-step up whose would-be predecessor is the divider', () => {
      const ul = dividedContainer();
      // "before c but after the divider" cannot be expressed as a previous
      // item id, so d moving up one slot is unavailable.
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'd'), direction: 'up' })).toBeUndefined();
    });

    it('keeps the extremes and same-chunk steps available', () => {
      const ul = dividedContainer();
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'a'), direction: 'down' })).toBe('b');
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'c'), direction: 'down' })).toBe('d');
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'b'), direction: 'top' })).toBeNull();
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'a'), direction: 'bottom' })).toBe('d');
      expect(resolveDirectionalPreviousItemId({ ...at(ul, 'd'), direction: 'top' })).toBeNull();
    });
  });
});

describe('resolveItemPosition', () => {
  function item(id:string, label?:string):HTMLLIElement {
    const row = document.createElement('li');
    row.setAttribute('data-sortable-lists--item-id-value', id);
    if (label) {
      row.setAttribute('data-sortable-lists--item-label-value', label);
    }
    return row;
  }

  function marker(omittedCount:number, prevItemId = '99'):HTMLLIElement {
    const row = document.createElement('li');
    row.setAttribute('data-sortable-lists-prev-item-id', prevItemId);
    row.setAttribute('data-sortable-lists-omitted-count', String(omittedCount));
    return row;
  }

  it('returns the 1-based position and total of an item row', () => {
    const container = document.createElement('ul');
    const rows = [item('1'), item('2'), item('3')];
    container.append(...rows);

    expect(resolveItemPosition({ row: rows[1], rowsContainer: container }))
      .toEqual({ position: 2, total: 3 });
  });

  it('counts the hidden items a truncation marker stands in for', () => {
    const container = document.createElement('ul');
    const before = item('1');
    const after = item('2');
    container.append(before, marker(40), after);

    expect(resolveItemPosition({ row: before, rowsContainer: container }))
      .toEqual({ position: 1, total: 42 });
    expect(resolveItemPosition({ row: after, rowsContainer: container }))
      .toEqual({ position: 42, total: 42 });
  });

  it('ignores non-item rows without an omitted count', () => {
    const container = document.createElement('ul');
    const divider = document.createElement('li');
    const row = item('1');
    container.append(divider, row);

    expect(resolveItemPosition({ row, rowsContainer: container }))
      .toEqual({ position: 1, total: 1 });
  });

  it('returns null for a row that is not an item row of the container', () => {
    const container = document.createElement('ul');
    container.append(item('1'));
    const foreign = item('2');

    expect(resolveItemPosition({ row: foreign, rowsContainer: container })).toBeNull();
    expect(resolveItemPosition({ row: marker(3), rowsContainer: container })).toBeNull();

    // Also test an in-container marker row
    const inContainerMarker = marker(5);
    container.append(inContainerMarker);
    expect(resolveItemPosition({ row: inContainerMarker, rowsContainer: container })).toBeNull();
  });
});

describe('resolveItemLabel', () => {
  it('reads the label from the row item element and returns null without one', () => {
    const labelled = document.createElement('li');
    labelled.setAttribute('data-sortable-lists--item-id-value', '1');
    labelled.setAttribute('data-sortable-lists--item-label-value', 'Story one');
    const bare = document.createElement('li');
    bare.setAttribute('data-sortable-lists--item-id-value', '2');

    expect(resolveItemLabel(labelled)).toEqual('Story one');
    expect(resolveItemLabel(bare)).toBeNull();
  });
});

describe('resolveItemType', () => {
  it('reads the item type value attribute', () => {
    const el = document.createElement('div');
    el.setAttribute('data-sortable-lists--item-type-value', 'custom_field');
    expect(resolveItemType(el)).toBe('custom_field');
  });

  it('returns null when the attribute is absent or empty', () => {
    const el = document.createElement('div');
    expect(resolveItemType(el)).toBeNull();
    el.setAttribute('data-sortable-lists--item-type-value', '');
    expect(resolveItemType(el)).toBeNull();
  });
});
