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

import { createSortableItemPayloadScope } from './payload';

describe('createSortableItemPayloadScope', () => {
  it('recognizes data created by the same scope', () => {
    const scope = createSortableItemPayloadScope();
    const data = scope.itemData('42', 'list');

    expect(scope.isItemData(data)).toBe(true);
    expect(data.itemId).toBe('42');
  });

  it('rejects data from another scope, even for an equal item id', () => {
    const scope = createSortableItemPayloadScope();
    const otherScope = createSortableItemPayloadScope();

    expect(scope.isItemData(otherScope.itemData('42', 'list'))).toBe(false);
    expect(otherScope.isItemData(scope.itemData('42', 'list'))).toBe(false);
  });

  it('rejects foreign and empty payloads', () => {
    const scope = createSortableItemPayloadScope();

    expect(scope.isItemData({})).toBe(false);
    expect(scope.isItemData({ itemId: '42' })).toBe(false);
  });

  it('rejects data with an empty item id', () => {
    const scope = createSortableItemPayloadScope();

    expect(scope.isItemData(scope.itemData('', 'list'))).toBe(false);
  });

  it('carries the list id in the payload', () => {
    const scope = createSortableItemPayloadScope();
    const data = scope.itemData('item-1', 'list-a');

    expect(data.itemId).toBe('item-1');
    expect(data.listId).toBe('list-a');
    expect(scope.isItemData(data)).toBe(true);
  });

  it('rejects payloads without a list id', () => {
    const scope = createSortableItemPayloadScope();

    expect(scope.isItemData({ itemId: 'item-1' })).toBe(false);
  });
});
