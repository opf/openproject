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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { analyzeMoveRows, analyzedMoveAvailability, resolveAnalyzedMove } from './move-analysis';
import {
  type MoveDirection,
  reorderRows,
  resolveBlockMove,
  resolveBlockMoveAvailability,
  resolveDirectionalPreviousItemId,
  resolveMoveAvailability,
} from './list-dom';

describe('row movement geometry', () => {
  function fixture(initial:string) {
    const rowsContainer = document.createElement('ul');
    const selected:HTMLElement[] = [];
    initial.split(' ').forEach((token) => {
      const row = document.createElement('li');
      const id = token.replaceAll('*', '');
      row.dataset.row = id;
      if (id === 'M(H)') {
        row.setAttribute('data-sortable-lists-prev-item-id', 'H');
        row.setAttribute('data-sortable-lists-omitted-count', '10');
      } else if (id !== 'D') {
        row.setAttribute('data-sortable-lists--item-id-value', id);
      }
      if (token.endsWith('*')) selected.push(row);
      rowsContainer.append(row);
    });
    return { rowsContainer, selected };
  }

  const cases:{ initial:string; direction:MoveDirection; result:string|null; predecessor?:string|null }[] = [
    { initial: '0 1 2* 3 4* 5', direction: 'up', result: '0 2 4 1 3 5', predecessor: '0' },
    { initial: '0* 1 2* 3', direction: 'up', result: '0 2 1 3', predecessor: null },
    { initial: '0* 1 2* 3', direction: 'top', result: '0 2 1 3', predecessor: null },
    { initial: '0* 1 2*', direction: 'down', result: '1 0 2', predecessor: '1' },
    { initial: 'A* B*', direction: 'up', result: null },
    { initial: 'A* B*', direction: 'top', result: null },
    { initial: 'A* B*', direction: 'down', result: null },
    { initial: 'A* B*', direction: 'bottom', result: null },
    { initial: 'A* M(H) B*', direction: 'up', result: null },
    { initial: 'A* M(H) B*', direction: 'down', result: null },
    { initial: 'A* M(H) B*', direction: 'top', result: 'A B M(H)', predecessor: null },
    { initial: 'A* M(H) B*', direction: 'bottom', result: 'M(H) A B', predecessor: 'H' },
    { initial: 'A* C* M(H) D', direction: 'down', result: null },
    { initial: 'A* D B* C', direction: 'top', result: 'A B D C', predecessor: null },
    { initial: 'A* D B* C', direction: 'up', result: null },
    { initial: 'A* D B* C', direction: 'down', result: null },
    { initial: 'D A*', direction: 'top', result: 'A D', predecessor: null },
    { initial: 'M(H) A*', direction: 'top', result: 'A M(H)', predecessor: null },
    { initial: 'A* B M(H)', direction: 'bottom', result: 'B M(H) A', predecessor: 'H' },
    { initial: 'A D B* C*', direction: 'up', result: null },
    { initial: 'D A B* C*', direction: 'up', result: null },
    { initial: 'A* B* D C', direction: 'down', result: null },
    { initial: 'A* D', direction: 'bottom', result: null },
    { initial: 'A B* C* D', direction: 'bottom', result: null },
  ];

  cases.forEach(({ initial, direction, result, predecessor }) => {
    it(`${initial} ${direction} -> ${result ?? 'unavailable'}`, () => {
      const { rowsContainer, selected } = fixture(initial);
      const resolution = resolveBlockMove({ itemElements: [...selected].reverse(), rowsContainer, direction });
      const availability = resolveBlockMoveAvailability({ itemElements: selected, rowsContainer });
      expect(resolution).toEqual(result === null
        ? { available: false }
        : { available: true, rows: selected, previousItemId: predecessor });
      expect(availability[direction]).toBe(result !== null);
      if (resolution.available) {
        reorderRows({ rowsContainer, rows: resolution.rows, previousItemId: resolution.previousItemId });
      }
      expect(Array.from(rowsContainer.children).map((row) => (row as HTMLElement).dataset.row).join(' '))
        .toBe(result ?? initial.replaceAll('*', ''));
    });
  });

  cases.filter(({ initial }) => initial.split('*').length === 2).forEach(({ initial, direction, result, predecessor }) => {
    it(`singleton wrappers agree for ${initial} ${direction}`, () => {
      const { rowsContainer, selected: [itemElement] } = fixture(initial);
      expect(resolveMoveAvailability({ itemElement, rowsContainer })?.[direction]).toBe(result !== null);
      expect(resolveDirectionalPreviousItemId({ itemElement, rowsContainer, direction }))
        .toBe(result === null ? undefined : predecessor);
    });
  });

  it('resolves a captured snapshot without consulting mutated DOM', () => {
    const { rowsContainer, selected } = fixture('A* B M(H)');
    const rows = Array.from(rowsContainer.children).map((element) => ({
      element: element as HTMLElement,
      isItem: element.hasAttribute('data-sortable-lists--item-id-value'),
      orderable: true,
      previousItemId: element.getAttribute('data-sortable-lists--item-id-value')
        ?? element.getAttribute('data-sortable-lists-prev-item-id'),
    }));
    const analysis = analyzeMoveRows(rows, selected);
    expect(analysis).not.toBeNull();
    if (!analysis) return;
    rowsContainer.replaceChildren();
    selected[0].removeAttribute('data-sortable-lists--item-id-value');
    selected[0].setAttribute('data-sortable-lists--item-mobility-value', 'fixed');

    expect(resolveAnalyzedMove(analysis, 'bottom'))
      .toEqual({ available: true, rows: selected, previousItemId: 'H' });
    expect(analyzedMoveAvailability(analysis)).toEqual({ top: false, up: false, down: true, bottom: true });
  });

  it('re-resolves a sparse selection after filtering an unselected row', () => {
    const { rowsContainer, selected } = fixture('0 1 2* 3 4* 5');
    rowsContainer.children[1].remove();
    const resolution = resolveBlockMove({ itemElements: selected, rowsContainer, direction: 'up' });
    expect(resolution).toEqual({ available: true, rows: selected, previousItemId: null });
  });
});
