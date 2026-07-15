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

// The Pragmatic DnD payload exchanged between draggable items and drop
// targets of one sortable list. Each list instance creates its own scope,
// keyed with a private Symbol, so items of one list can never be recognized
// by the targets, monitors or autoscrollers of another — even when both
// lists contain items with equal ids.
export interface SortableItemData extends Record<string|symbol, unknown> {
  itemId:string;
}

export interface SortableItemPayloadScope {
  itemData(itemId:string):SortableItemData;
  isItemData(data:Record<string|symbol, unknown>):data is SortableItemData;
}

export function createSortableItemPayloadScope():SortableItemPayloadScope {
  const scopeKey = Symbol('op-sortable-item');

  return {
    itemData(itemId:string):SortableItemData {
      return {
        [scopeKey]: true,
        itemId,
      };
    },

    isItemData(data:Record<string|symbol, unknown>):data is SortableItemData {
      return data[scopeKey] === true
        && typeof data.itemId === 'string'
        && data.itemId.length > 0;
    },
  };
}
