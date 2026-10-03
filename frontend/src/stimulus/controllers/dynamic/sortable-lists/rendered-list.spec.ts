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

import { type RenderedList, renderList, placementAtEdge, placementAtEnd, placementAtStart, directionalPlacement, moveAvailability, positionOf, anchorRow, rangeBetween, neighbourItemRow, boundaryItemRow, movableItems } from './rendered-list';
import { type ExcludedItems } from './list-dom';

describe('rendered sortable list', () => {
  function itemRow(id:string, { type = 'work_package', mobility = 'free' }:{ type?:string|null; mobility?:string } = {}):HTMLLIElement {
    const row = document.createElement('li');
    const item = document.createElement('article');
    item.setAttribute('data-sortable-lists--item-id-value', id);
    if (type !== null) item.setAttribute('data-sortable-lists--item-type-value', type);
    item.setAttribute('data-sortable-lists--item-mobility-value', mobility);
    row.appendChild(item);
    return row;
  }

  function showMoreRow(previousItemId = 'hidden-item', omitted = 0):HTMLLIElement {
    const row = document.createElement('li');
    row.setAttribute('data-sortable-lists-prev-item-id', previousItemId);
    if (omitted > 0) row.setAttribute('data-sortable-lists-omitted-count', String(omitted));
    return row;
  }

  function dividerRow():HTMLLIElement {
    return document.createElement('li');
  }

  function list(...rows:HTMLElement[]):HTMLUListElement {
    const container = document.createElement('ul');
    container.append(...rows);
    document.body.append(container);
    return container;
  }

  function excluding(...ids:string[]):ExcludedItems {
    return { type: 'work_package', ids: new Set(ids) };
  }

  const rowById = (list:RenderedList, id:string) => list.rows.find((row) => row.item?.id === id)!;

  afterEach(() => {
    document.body.replaceChildren();
  });
  describe('renderList', () => {
    it('classifies item, marker and gap rows', () => {
      const container = list(itemRow('1'), showMoreRow('hidden', 3), dividerRow());
      const { rows } = renderList(container);

      expect(rows.map((row) => row.item?.id ?? null)).toEqual(['1', null, null]);
      expect(rows.map((row) => row.predecessorId)).toEqual(['1', 'hidden', null]);
      expect(rows[1].omittedCount).toBe(3);
    });

    it('ignores items of a nested list when listing item rows', () => {
      const section = itemRow('section-1', { type: 'section' });
      const inner = document.createElement('ul');
      inner.append(itemRow('field-5', { type: 'custom_field' }));
      section.append(inner);
      const container = list(section, itemRow('section-2', { type: 'section' }));

      expect(renderList(container).itemRows().map((row) => row.item!.id)).toEqual(['section-1', 'section-2']);
    });

    it('treats a row whose item has no id as a gap', () => {
      const row = document.createElement('li');
      const item = document.createElement('article');
      item.setAttribute('data-sortable-lists--item-type-value', 'work_package');
      row.append(item);
      const container = list(itemRow('1'), row);

      expect(renderList(container).rows[1].item).toBeNull();
      expect(renderList(container).rows[1].predecessorId).toBeNull();
    });

    it('reads a row that is itself the item, as consumers render it', () => {
      const row = document.createElement('li');
      row.setAttribute('data-sortable-lists--item-id-value', '7');
      row.setAttribute('data-sortable-lists--item-type-value', 'work_package');
      const container = list(row);
      const rendered = renderList(container);

      expect(rendered.rows[0].item?.element).toBe(row);
      expect(rendered.rowOf(row)).toBe(rendered.rows[0]);
    });

    it('treats a marker with an empty hidden id as a gap', () => {
      const container = list(itemRow('1'), showMoreRow(''), itemRow('2'));
      const rendered = renderList(container);

      expect(rendered.rows[1].predecessorId).toBeNull();
      expect(placementAtEdge(rendered, rowById(rendered, '2'), 'top', excluding('x'))).toEqual({ previousItemId: '1' });
    });

    it('resolves the row holding a nested element and null for the container', () => {
      const container = list(itemRow('1'), itemRow('2'));
      const rendered = renderList(container);
      const nested = container.children[1].firstElementChild!;

      expect(rendered.rowOf(nested)?.item?.id).toBe('2');
      expect(rendered.rowOf(container)).toBeNull();
    });
  });

  describe('placementAtEnd', () => {
    it('returns the last item while skipping excluded and marker rows', () => {
      const container = list(itemRow('1'), showMoreRow(), itemRow('2'), itemRow('3'));

      expect(placementAtEnd(renderList(container), excluding('3'))).toEqual({ previousItemId: '2' });
    });

    it('anchors on a trailing marker when the last visible item is excluded', () => {
      const container = list(itemRow('1'), itemRow('2'), showMoreRow('hidden'));

      expect(placementAtEnd(renderList(container), excluding('2'))).toEqual({ previousItemId: 'hidden' });
    });

    it('returns the top for an empty list nested inside an outer item', () => {
      const section = itemRow('s1', { type: 'section' });
      const inner = document.createElement('ul');
      section.append(inner);
      list(section);

      expect(placementAtEnd(renderList(inner), excluding('x'))).toEqual({ previousItemId: null });
    });

    it('returns the top when the list has no other items', () => {
      const container = list(itemRow('1'));

      expect(placementAtEnd(renderList(container), excluding('1'))).toEqual({ previousItemId: null });
    });
  });

  it('placementAtStart is the top of the list', () => {
    expect(placementAtStart()).toEqual({ previousItemId: null });
  });

  describe('placementAtEdge', () => {
    it('lands after the target on its bottom edge', () => {
      const container = list(itemRow('1'), itemRow('2'), itemRow('3'));
      const rendered = renderList(container);

      expect(placementAtEdge(rendered, rowById(rendered, '2'), 'bottom', excluding('3'))).toEqual({ previousItemId: '2' });
    });

    it('lands before the target on its top edge', () => {
      const container = list(itemRow('1'), itemRow('2'), itemRow('3'));
      const rendered = renderList(container);

      expect(placementAtEdge(rendered, rowById(rendered, '2'), 'top', excluding('3'))).toEqual({ previousItemId: '1' });
      expect(placementAtEdge(rendered, rowById(rendered, '1'), 'top', excluding('3'))).toEqual({ previousItemId: null });
    });

    it('skips excluded batch members and reads a marker above', () => {
      const container = list(showMoreRow('hidden'), itemRow('1'), itemRow('2'), itemRow('3'));
      const rendered = renderList(container);

      expect(placementAtEdge(rendered, rowById(rendered, '3'), 'top', excluding('1', '2'))).toEqual({ previousItemId: 'hidden' });
    });

    it('refuses an excluded target as the bottom-edge anchor', () => {
      const container = list(itemRow('1'), itemRow('2'), itemRow('3'));
      const rendered = renderList(container);

      expect(placementAtEdge(rendered, rowById(rendered, '2'), 'bottom', excluding('2'))).toEqual({ previousItemId: '1' });
    });

    it('treats a missing edge as dropping before the target', () => {
      const container = list(itemRow('1'), itemRow('2'));
      const rendered = renderList(container);

      expect(placementAtEdge(rendered, rowById(rendered, '2'), null, excluding('x'))).toEqual({ previousItemId: '1' });
    });

    it('resolves a target given as its row or a descendant of the item', () => {
      const container = list(itemRow('1'), itemRow('2'));
      const rendered = renderList(container);
      const rowElement = container.children[1];
      const descendant = rowElement.firstElementChild!;

      expect(placementAtEdge(rendered, rendered.rowOf(rowElement)!, 'bottom', excluding('x'))).toEqual({ previousItemId: '2' });
      expect(placementAtEdge(rendered, rendered.rowOf(descendant)!, 'top', excluding('x'))).toEqual({ previousItemId: '1' });
    });

    it('keeps excluding a truncation marker whose hidden id collides with the batch', () => {
      const container = list(showMoreRow('1'), itemRow('2'));
      const rendered = renderList(container);

      expect(placementAtEdge(rendered, rowById(rendered, '2'), 'top', excluding('1'))).toEqual({ previousItemId: null });
    });

    it('excludes only a same-type id', () => {
      const container = list(itemRow('1', { type: 'section' }), itemRow('2'));
      const rendered = renderList(container);

      expect(placementAtEdge(rendered, rowById(rendered, '2'), 'top', excluding('1'))).toEqual({ previousItemId: '1' });
    });
  });

  describe('directionalPlacement', () => {
    it('maps each direction to a placement', () => {
      const container = list(itemRow('1'), itemRow('2'), itemRow('3'));
      const rendered = renderList(container);
      const row = rowById(rendered, '2');

      expect(directionalPlacement(rendered, row, 'top')).toEqual({ previousItemId: null });
      expect(directionalPlacement(rendered, row, 'up')).toEqual({ previousItemId: null });
      expect(directionalPlacement(rendered, row, 'down')).toEqual({ previousItemId: '3' });
      expect(directionalPlacement(rendered, row, 'bottom')).toEqual({ previousItemId: '3' });
    });

    it('mirrors up and down between neighbours', () => {
      const container = list(itemRow('1'), itemRow('2'), itemRow('3'));
      const rendered = renderList(container);

      expect(directionalPlacement(rendered, rowById(rendered, '3'), 'up')).toEqual({ previousItemId: '1' });
      expect(directionalPlacement(rendered, rowById(rendered, '1'), 'down')).toEqual({ previousItemId: '2' });
    });

    it('is unavailable at the extremes', () => {
      const container = list(itemRow('1'), itemRow('2'));
      const rendered = renderList(container);

      expect(directionalPlacement(rendered, rowById(rendered, '1'), 'top')).toBeNull();
      expect(directionalPlacement(rendered, rowById(rendered, '1'), 'up')).toBeNull();
      expect(directionalPlacement(rendered, rowById(rendered, '2'), 'down')).toBeNull();
      expect(directionalPlacement(rendered, rowById(rendered, '2'), 'bottom')).toBeNull();
    });

    describe('across a truncation marker', () => {
      // head + hidden block + tail
      const build = () => list(itemRow('1'), itemRow('2'), showMoreRow('hidden-last', 4), itemRow('3'), itemRow('4'));

      it('disables a one-step move that would cross the hidden block', () => {
        const container = build();
        const rendered = renderList(container);

        expect(directionalPlacement(rendered, rowById(rendered, '2'), 'down')).toBeNull();
      });

      it('anchors a tail item stepping up onto the hidden block via the marker id', () => {
        const container = build();
        const rendered = renderList(container);

        expect(directionalPlacement(rendered, rowById(rendered, '4'), 'up')).toEqual({ previousItemId: 'hidden-last' });
      });

      it('keeps the extremes available across the block', () => {
        const container = build();
        const rendered = renderList(container);

        expect(directionalPlacement(rendered, rowById(rendered, '1'), 'bottom')).toEqual({ previousItemId: '4' });
        expect(directionalPlacement(rendered, rowById(rendered, '4'), 'top')).toEqual({ previousItemId: null });
      });
    });

    describe('across an unannotated divider', () => {
      const build = () => list(itemRow('1'), itemRow('2'), dividerRow(), itemRow('3'), itemRow('4'));

      it('disables one-step moves whose neighbouring row is the divider', () => {
        const container = build();
        const rendered = renderList(container);

        expect(directionalPlacement(rendered, rowById(rendered, '2'), 'down')).toBeNull();
        expect(directionalPlacement(rendered, rowById(rendered, '3'), 'up')).toBeNull();
      });

      it('disables a one-step up whose would-be predecessor is the divider', () => {
        const container = build();
        const rendered = renderList(container);

        expect(directionalPlacement(rendered, rowById(rendered, '4'), 'up')).toBeNull();
      });

      it('keeps the extremes and same-chunk steps available', () => {
        const container = build();
        const rendered = renderList(container);

        expect(directionalPlacement(rendered, rowById(rendered, '1'), 'down')).toEqual({ previousItemId: '2' });
        expect(directionalPlacement(rendered, rowById(rendered, '4'), 'top')).toEqual({ previousItemId: null });
      });
    });
  });

  describe('moveAvailability', () => {
    it('reports per-direction availability', () => {
      const container = list(itemRow('1'), itemRow('2'));
      const rendered = renderList(container);

      expect(moveAvailability(rendered, rowById(rendered, '1'))).toEqual({ top: false, up: false, down: true, bottom: true });
    });
  });

  describe('positionOf', () => {
    it('returns the 1-based position and total of an item row', () => {
      const container = list(itemRow('1'), itemRow('2'), itemRow('3'));
      const rendered = renderList(container);

      expect(positionOf(rendered, rowById(rendered, '2'))).toEqual({ position: 2, total: 3 });
    });

    it('counts the hidden items a truncation marker stands in for', () => {
      const container = list(itemRow('1'), showMoreRow('hidden', 5), itemRow('2'));
      const rendered = renderList(container);

      expect(positionOf(rendered, rowById(rendered, '2'))).toEqual({ position: 7, total: 7 });
    });

    it('ignores non-item rows without an omitted count', () => {
      const container = list(itemRow('1'), dividerRow(), itemRow('2'));
      const rendered = renderList(container);

      expect(positionOf(rendered, rowById(rendered, '2'))).toEqual({ position: 2, total: 2 });
    });
  });

  it('positionOf is null for a row that is not an item row', () => {
    const container = list(itemRow('1'), showMoreRow('hidden', 2));
    const rendered = renderList(container);

    expect(positionOf(rendered, rendered.rows[1])).toBeNull();
  });

  describe('anchorRow', () => {
    it('finds the row carrying the id, marker rows included', () => {
      const container = list(itemRow('1'), showMoreRow('hidden'), itemRow('2'));
      const rendered = renderList(container);

      expect(anchorRow(rendered, 'hidden')?.element).toBe(container.children[1]);
      expect(anchorRow(rendered, '2')?.item?.id).toBe('2');
      expect(anchorRow(rendered, 'missing')).toBeNull();
    });

    it('does not match a nested item with a colliding id', () => {
      const section = itemRow('5', { type: 'section' });
      const inner = document.createElement('ul');
      inner.append(itemRow('5', { type: 'custom_field' }));
      section.append(inner);
      const container = list(itemRow('4', { type: 'section' }), section);

      expect(anchorRow(renderList(container), '5')?.element).toBe(section);
    });
  });

  describe('rangeBetween', () => {
    const wp = (id:string) => ({ type: 'work_package', id });

    it('spans movable items between anchor and candidate in either direction', () => {
      const container = list(itemRow('1'), itemRow('2'), itemRow('3'));
      const rendered = renderList(container);

      expect(rangeBetween(rendered, wp('1'), container.children[2])).toEqual({ ok: true, items: [wp('1'), wp('2'), wp('3')] });
      expect(rangeBetween(rendered, wp('3'), container.children[0])).toEqual({ ok: true, items: [wp('1'), wp('2'), wp('3')] });
    });

    it('is unavailable across a truncation marker', () => {
      const container = list(itemRow('1'), showMoreRow(), itemRow('2'));

      expect(rangeBetween(renderList(container), wp('1'), container.children[2])).toEqual({ ok: false, reason: 'unavailable' });
    });

    it('is locked across a fixed item', () => {
      const container = list(itemRow('1'), itemRow('2', { mobility: 'fixed' }), itemRow('3'));

      expect(rangeBetween(renderList(container), wp('1'), container.children[2])).toEqual({ ok: false, reason: 'locked' });
    });

    it('is unavailable when the anchor is not a row of this list', () => {
      const container = list(itemRow('1'), itemRow('2'));

      expect(rangeBetween(renderList(container), wp('9'), container.children[1])).toEqual({ ok: false, reason: 'unavailable' });
    });

    it('is unavailable across a row that only hosts a nested list', () => {
      const wrapper = document.createElement('li');
      const inner = document.createElement('ul');
      inner.append(itemRow('9'));
      wrapper.append(inner);
      const container = list(itemRow('1'), wrapper, itemRow('2'));

      expect(rangeBetween(renderList(container), wp('1'), container.children[2])).toEqual({ ok: false, reason: 'unavailable' });
    });

    it('is unavailable when the candidate sits outside the rows container', () => {
      const container = list(itemRow('1'), itemRow('2'));
      const stray = itemRow('3');
      document.body.append(stray);

      expect(rangeBetween(renderList(container), wp('1'), stray)).toEqual({ ok: false, reason: 'unavailable' });
    });

    it('matches the anchor on type as well as id', () => {
      const container = list(itemRow('1', { type: 'section' }), itemRow('2'));

      expect(rangeBetween(renderList(container), wp('1'), container.children[1])).toEqual({ ok: false, reason: 'unavailable' });
    });
  });

  describe('navigation', () => {
    it('steps through items as rendered, fixed ones included', () => {
      const container = list(itemRow('1'), itemRow('2', { mobility: 'fixed' }), itemRow('3'));
      const rendered = renderList(container);

      expect(neighbourItemRow(rendered, container.children[0], 1)?.item?.id).toBe('2');
      expect(neighbourItemRow(rendered, container.children[2], -1)?.item?.id).toBe('2');
      expect(neighbourItemRow(rendered, container.children[2], 1)).toBeNull();
    });

    it('lands Home and End on the first and last movable item', () => {
      const container = list(itemRow('1', { mobility: 'fixed' }), itemRow('2'), itemRow('3'), itemRow('4', { mobility: 'fixed' }));
      const rendered = renderList(container);

      expect(boundaryItemRow(rendered, 'first')?.item?.id).toBe('2');
      expect(boundaryItemRow(rendered, 'last')?.item?.id).toBe('3');
    });

    it('does not step into a list nested inside the list', () => {
      const section = itemRow('s1', { type: 'section' });
      const inner = document.createElement('ul');
      inner.append(itemRow('f1', { type: 'custom_field' }));
      section.append(inner);
      const container = list(section, itemRow('s2', { type: 'section' }));
      const rendered = renderList(container);

      expect(neighbourItemRow(rendered, section, 1)?.item?.id).toBe('s2');
      expect(movableItems(rendered).map((item) => item.id)).toEqual(['s1', 's2']);
    });

    it('returns null when no movable item remains in the list', () => {
      const container = list(itemRow('1', { mobility: 'fixed' }));

      expect(boundaryItemRow(renderList(container), 'first')).toBeNull();
    });

    it('lists the movable items with a type', () => {
      const container = list(itemRow('1'), itemRow('2', { mobility: 'fixed' }), itemRow('3', { type: null }), itemRow('4'));

      expect(movableItems(renderList(container))).toEqual([{ type: 'work_package', id: '1' }, { type: 'work_package', id: '4' }]);
    });
  });
});
