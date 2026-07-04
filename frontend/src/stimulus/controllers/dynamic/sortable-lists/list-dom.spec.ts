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

import {
  captureRowPositions,
  reorderRows,
  resolveItemElement,
  resolveItemPosition,
  resolveListAppendPreviousItemId,
  resolveRow,
  resolveRowsContainer,
  restoreRowPositions,
} from './list-dom';

describe('sortable lists DOM helpers', () => {
  function itemRow(id:string):HTMLLIElement {
    const row = document.createElement('li');
    const item = document.createElement('article');

    row.setAttribute('data-sortable-lists--item-id-value', id);
    row.appendChild(item);

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
      const container = listElement();

      container.append(itemRow('1'), showMoreRow(), itemRow('2'), itemRow('3'));

      expect(resolveListAppendPreviousItemId({ sourceItemId: '3', container })).toEqual('2');
    });

    it('returns null when the list has no other items', () => {
      const container = listElement();

      container.append(itemRow('1'));

      expect(resolveListAppendPreviousItemId({ sourceItemId: '1', container })).toBeNull();
    });
  });

  describe('reorderRows', () => {
    it('moves a row to sit immediately after the previous item anchor', () => {
      const container = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      container.append(one, two, three);
      reorderRows({ rows: [one], container, previousItemId: '2' });

      expect(itemIdOrder(container)).toEqual(['2', '1', '3']);
    });

    it('moves a row to the top of the list before the first existing row', () => {
      const container = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      container.append(one, two, three);
      reorderRows({ rows: [three], container, previousItemId: null });

      expect(itemIdOrder(container)).toEqual(['3', '1', '2']);
    });

    it('reorders section rows in a plain div container', () => {
      const container = document.createElement('div');
      container.innerHTML = `
        <section data-sortable-lists--item-id-value="a"></section>
        <section data-sortable-lists--item-id-value="b"></section>`;
      const [a, b] = Array.from(container.children) as HTMLElement[];
      reorderRows({ rows: [a], container, previousItemId: 'b' });
      expect(Array.from(container.children)).toEqual([b, a]);
    });

    it('inserts a moved group after the anchor preserving their order', () => {
      const container = listElement();
      const [one, two, three, four] = ['1', '2', '3', '4'].map(itemRow);

      container.append(one, two, three, four);
      reorderRows({ rows: [three, four], container, previousItemId: '1' });

      expect(itemIdOrder(container)).toEqual(['1', '3', '4', '2']);
    });

    it('anchors on a truncation marker row when the previous item is hidden', () => {
      const container = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);
      const marker = showMoreRow('hidden');

      container.append(three, one, marker, two);
      reorderRows({ rows: [three], container, previousItemId: 'hidden' });

      expect(three.previousElementSibling).toBe(marker);
      expect(itemIdOrder(container)).toEqual(['1', '3', '2']);
    });
  });

  describe('captureRowPositions / restoreRowPositions', () => {
    it('restores a row to its original position after an optimistic move', () => {
      const container = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      container.append(one, two, three);
      const snapshot = captureRowPositions([three]);

      reorderRows({ rows: [three], container, previousItemId: null });
      expect(itemIdOrder(container)).toEqual(['3', '1', '2']);

      restoreRowPositions(snapshot);
      expect(itemIdOrder(container)).toEqual(['1', '2', '3']);
    });

    it('restores a multi-row group to its original order', () => {
      const container = listElement();
      const [one, two, three, four] = ['1', '2', '3', '4'].map(itemRow);

      container.append(one, two, three, four);
      const snapshot = captureRowPositions([two, three]);

      reorderRows({ rows: [two, three], container, previousItemId: '4' });
      expect(itemIdOrder(container)).toEqual(['1', '4', '2', '3']);

      restoreRowPositions(snapshot);
      expect(itemIdOrder(container)).toEqual(['1', '2', '3', '4']);
    });

    it('falls back to appending when the captured next sibling is stale', () => {
      const container = listElement();
      const [one, two] = ['1', '2'].map(itemRow);

      container.append(one, two);
      const snapshot = captureRowPositions([one]);
      two.remove();

      expect(() => restoreRowPositions(snapshot)).not.toThrow();
      expect(itemIdOrder(container)).toEqual(['1']);
    });
  });

  describe('resolveRowsContainer', () => {
    it('returns the list element itself when no selector value is set', () => {
      const list = document.createElement('div');
      expect(resolveRowsContainer(list)).toBe(list);
    });

    it('returns the matched descendant when a selector value is set', () => {
      const list = document.createElement('div');
      list.setAttribute('data-sortable-lists--list-rows-container-selector-value', ':scope > ul');
      const ul = document.createElement('ul');
      list.append(ul);
      expect(resolveRowsContainer(list)).toBe(ul);
    });

    it('falls back to the list element when the selector matches nothing', () => {
      const list = document.createElement('div');
      list.setAttribute('data-sortable-lists--list-rows-container-selector-value', ':scope > ul');
      expect(resolveRowsContainer(list)).toBe(list);
    });
  });

  describe('resolveRow', () => {
    it('returns the direct child containing a nested element', () => {
      const container = document.createElement('ul');
      container.innerHTML = '<li><div class="card"><span class="deep"></span></div></li>';
      const row = container.firstElementChild as HTMLElement;
      expect(resolveRow(container, container.querySelector('.deep')!)).toBe(row);
    });

    it('returns the element itself when it is a direct child', () => {
      const container = document.createElement('div');
      container.innerHTML = '<section id="s"></section>';
      const section = container.querySelector('#s')!;
      expect(resolveRow(container, section)).toBe(section);
    });

    it('returns null for an element outside the container', () => {
      expect(resolveRow(document.createElement('div'), document.createElement('span'))).toBeNull();
    });
  });

  describe('resolveItemElement with nested sortable items', () => {
    // #23893 / AGILE-292 dual-role shape: an outer item surface (bucket) hosting
    // a nested inner sortable list with its own item rows.
    function dualRoleFixture() {
      const outerRow = document.createElement('li');
      outerRow.innerHTML = `
        <section data-sortable-lists--item-id-value="outer">
          <ul><li><div data-sortable-lists--item-id-value="inner"></div></li></ul>
        </section>`;
      return {
        outerRow,
        innerRow: outerRow.querySelector<HTMLElement>('ul > li')!,
      };
    }

    it('resolves an inner row to its own descendant item, never an ancestor surface', () => {
      // The bug this guards: closest()-based resolution walks OUT of the row and
      // finds the outer bucket's item surface instead of the row's own card.
      const { innerRow } = dualRoleFixture();
      expect(resolveItemElement(innerRow)?.getAttribute('data-sortable-lists--item-id-value')).toBe('inner');
    });

    it('resolves an outer row to its own item surface, not a nested descendant', () => {
      const { outerRow } = dualRoleFixture();
      expect(resolveItemElement(outerRow)?.getAttribute('data-sortable-lists--item-id-value')).toBe('outer');
    });
  });

  describe('resolveItemPosition', () => {
    function containerWith(ids:(string|null)[]):HTMLElement {
      const ul = document.createElement('ul');
      ids.forEach((id) => {
        const li = document.createElement('li');
        if (id) { li.setAttribute('data-sortable-lists--item-id-value', id); }
        ul.append(li);
      });
      return ul;
    }

    it('returns 1 for a null previous item (top of list)', () => {
      expect(resolveItemPosition({ container: containerWith(['a', 'b']), previousItemId: null })).toBe(1);
    });

    it('returns the position after the previous item, counting only item rows', () => {
      // non-item row (e.g. blankslate / show-more marker) between a and b
      expect(resolveItemPosition({ container: containerWith(['a', null, 'b']), previousItemId: 'a' })).toBe(2);
      expect(resolveItemPosition({ container: containerWith(['a', null, 'b']), previousItemId: 'b' })).toBe(3);
    });
  });
});
