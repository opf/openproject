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
  isOrderableItem,
  itemAcceptsDestination,
  itemMobility,
  sortableItemMobilityAttribute,
  resolveItemLabel,
  resolveItemType,
  resolveItemElement,
} from './list-dom';

describe('sortable lists DOM helpers', () => {
  function itemRow(id:string):HTMLLIElement {
    const row = document.createElement('li');
    const item = document.createElement('article');

    row.setAttribute('data-sortable-lists--item-id-value', id);
    row.appendChild(item);

    return row;
  }



  function listElement():HTMLUListElement {
    const list = document.createElement('ul');

    list.setAttribute('data-sortable-lists-target', 'list');

    return list;
  }



  describe('resolveItemElement', () => {
    it('does not descend into a nested list for a wrapper row', () => {
      const list = listElement();
      const wrapper = document.createElement('li');
      const nested = listElement();
      nested.append(itemRow('9'));
      wrapper.append(nested);
      list.append(wrapper);

      expect(resolveItemElement(wrapper, list)).toBeNull();
    });

    it('resolves the item a row wraps directly', () => {
      const list = listElement();
      const wrapper = document.createElement('li');
      const item = itemRow('1');
      wrapper.append(item);
      list.append(wrapper);

      expect(resolveItemElement(wrapper, list)).toBe(item);
    });
  });
});

describe('itemMobility', () => {
  function itemWith(mobility?:string):HTMLElement {
    const item = document.createElement('li');
    item.setAttribute('data-sortable-lists--item-id-value', '1');

    if (mobility !== undefined) {
      item.setAttribute(sortableItemMobilityAttribute, mobility);
    }

    return item;
  }

  it('defaults a missing attribute to free', () => {
    expect(itemMobility(itemWith())).toBe('free');
  });

  it.each(['fixed', 'confined', 'free'])('reads the recognised value %s', (value) => {
    expect(itemMobility(itemWith(value))).toBe(value);
  });

  // A typo must not hand the user a draggable, selectable card that only
  // fails once the request comes back.
  it('falls back to fixed for an unrecognised value', () => {
    expect(itemMobility(itemWith('movable'))).toBe('fixed');
  });

  it('treats an empty attribute as unrecognised', () => {
    expect(itemMobility(itemWith(''))).toBe('fixed');
  });

  it('derives orderable from the union', () => {
    expect(isOrderableItem(itemWith('free'))).toBe(true);
    expect(isOrderableItem(itemWith('confined'))).toBe(true);
    expect(isOrderableItem(itemWith('fixed'))).toBe(false);
  });
});

describe('itemAcceptsDestination', () => {
  const sprint1 = { type: 'sprint', id: '1' };
  const sprint2 = { type: 'sprint', id: '2' };

  function item(mobility:'fixed'|'confined'|'free' = 'free'):HTMLElement {
    const element = document.createElement('li');
    element.setAttribute(sortableItemMobilityAttribute, mobility);
    return element;
  }

  it('answers for one item which destinations it accepts', () => {
    const ownerDestinationOf = () => sprint1;

    expect(itemAcceptsDestination(item(), sprint2, ownerDestinationOf)).toBe(true);
    expect(itemAcceptsDestination(item('fixed'), sprint1, ownerDestinationOf)).toBe(false);
    expect(itemAcceptsDestination(item('confined'), sprint1, ownerDestinationOf)).toBe(true);
    expect(itemAcceptsDestination(item('confined'), sprint2, ownerDestinationOf)).toBe(false);
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
