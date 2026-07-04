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

import { dropTargetForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { type DragLocationHistory } from '@atlaskit/pragmatic-drag-and-drop/types';
import { Controller } from '@hotwired/stimulus';
import type SortableListsController from '../sortable-lists.controller';
import {
  isItemFromRoot,
  isSortableItemData,
  listAcceptsType,
  sortableListData,
  type SortableListData,
  type SortableListDropPosition,
} from './drag-and-drop';

type CleanupFn = () => void;

const dropPositions = new Set<string>(['start', 'end']);

export default class ListController extends Controller<HTMLElement> {
  static outlets = ['sortable-lists'];

  static values = {
    type: String,
    id: String,
    dropPosition: { type: String, default: 'end' },
    acceptedTypes: Array,
    // Consumed by list-dom.ts via the rendered attribute; declared here so the
    // list's public API is complete in one place.
    rowsContainerSelector: String,
  };

  declare readonly sortableListsOutlet:SortableListsController;
  declare readonly hasSortableListsOutlet:boolean;

  declare readonly typeValue:string;
  declare readonly idValue:string;
  declare readonly hasIdValue:boolean;
  declare readonly dropPositionValue:string;
  declare readonly acceptedTypesValue:string[];
  declare readonly hasAcceptedTypesValue:boolean;

  private cleanupFn?:CleanupFn;

  connect():void {
    // A list without accepted types is not a drop target (display-only list).
    if (!this.hasAcceptedTypesValue || this.acceptedTypesValue.length === 0) {
      return;
    }

    // The type doubles as the persisted list_type: a droppable list without it
    // would accept drops it cannot persist. Surface that wiring mistake.
    if (this.typeValue === '') {
      console.warn('sortable-lists--list has acceptedTypes but is missing its required type value (data-sortable-lists--list-type-value); it cannot accept drops.', this.element);
      return;
    }

    this.cleanupFn = dropTargetForElements({
      element: this.element,
      canDrop: ({ source }) => this.canDrop(source.data),
      getData: () => this.listData,
      getIsSticky: () => false,
      onDragEnter: ({ location }) => {
        this.syncDropIndicator(location);
      },
      onDrag: ({ location }) => {
        this.syncDropIndicator(location);
      },
      onDragLeave: () => {
        this.clearDropIndicator();
      },
      onDrop: () => {
        this.clearDropIndicator();
      },
    });
  }

  disconnect():void {
    this.cleanupFn?.();
    this.cleanupFn = undefined;
  }

  private get dropPosition():SortableListDropPosition {
    return dropPositions.has(this.dropPositionValue) ? this.dropPositionValue as SortableListDropPosition : 'end';
  }

  private get listData():SortableListData {
    return sortableListData({
      type: this.typeValue,
      listId: this.hasIdValue ? this.idValue : null,
      dropPosition: this.dropPosition,
    });
  }

  private canDrop(data:Record<string|symbol, unknown>):boolean {
    if (!this.hasSortableListsOutlet) {
      return false;
    }

    return isItemFromRoot(this.sortableListsOutlet.element, data)
      && listAcceptsType({ acceptedTypes: this.acceptedTypesValue, type: data.type });
  }

  // The list is the item targets' parent drop target, so its onDrag keeps firing
  // while the pointer is over a row. Outline the container only for a list-only
  // drop (no item target in play), so the row gap indicator owns that case.
  private syncDropIndicator(location:DragLocationHistory):void {
    if (location.current.dropTargets.some(({ data }) => isSortableItemData(data))) {
      this.clearDropIndicator();
    } else {
      this.renderDropIndicator();
    }
  }

  private renderDropIndicator():void {
    this.element.dataset.dropContainer = 'active';
  }

  private clearDropIndicator():void {
    delete this.element.dataset.dropContainer;
  }
}
