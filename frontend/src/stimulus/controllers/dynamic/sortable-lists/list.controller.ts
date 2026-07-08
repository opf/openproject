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
import {
  isItemFromRoot,
  isSortableItemData,
  sortableListData,
  type RootAwareChild,
  type SortableListData,
  type SortableListDropPosition,
  type SortableListsRoot,
} from './drag-and-drop';

type CleanupFn = () => void;

const dropPositions = new Set<string>(['start', 'end']);

export default class ListController extends Controller<HTMLElement> implements RootAwareChild {
  static values = {
    type: String,
    id: String,
    dropPosition: { type: String, default: 'end' },
    acceptedType: String,
  };

  static elements = { rowsContainer: ':scope > ul' };

  declare readonly typeValue:string;
  declare readonly hasTypeValue:boolean;
  declare readonly idValue:string;
  declare readonly hasIdValue:boolean;
  declare readonly dropPositionValue:string;
  declare readonly acceptedTypeValue:string;
  declare readonly hasAcceptedTypeValue:boolean;

  // Provided by the stimulus-elements blessing, declared manually in the same
  // style as the controller's values/targets.
  declare readonly rowsContainerElement:HTMLElement|null;
  declare readonly hasRowsContainerElement:boolean;

  private root?:SortableListsRoot;
  private cleanupFn?:CleanupFn;

  connect():void {
    this.register();
  }

  private register():void {
    // A list that accepts no item type is not a drop target (display-only).
    if (!this.hasAcceptedTypeValue) {
      return;
    }

    // The list's own type doubles as the persisted list_type: a droppable list
    // without it would accept drops it cannot persist. Surface that mistake.
    if (!this.hasTypeValue) {
      console.warn(
        'sortable-lists--list has an accepted type but is missing its required type value '
        + '(data-sortable-lists--list-type-value); it cannot accept drops.',
        this.element,
      );
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
    this.disconnectRoot();
  }

  // Re-establish the Pragmatic DnD registration from controller state; see the
  // item controller's reregister for why the root calls this after a morph.
  reregister():void {
    this.cleanupFn?.();
    this.cleanupFn = undefined;
    this.register();
  }

  // Called by the root controller's outlet-connected callback.
  connectRoot(root:SortableListsRoot):void {
    this.root = root;
    this.reflectBusy(root.busy);
  }

  disconnectRoot():void {
    this.root = undefined;
    // The root only reaches still-connected list outlets when it ends a move, so
    // a list that disconnects mid-move would otherwise keep aria-busy forever.
    this.reflectBusy(false);
  }

  reflectBusy(busy:boolean):void {
    if (busy) {
      this.element.setAttribute('aria-busy', 'true');
    } else {
      this.element.removeAttribute('aria-busy');
    }
  }

  private get dropPosition():SortableListDropPosition {
    return dropPositions.has(this.dropPositionValue) ? this.dropPositionValue as SortableListDropPosition : 'end';
  }

  // Rows sit inside a child rows container (the Box list's <ul>). Lists that
  // render rows directly under their own element have no such child, so fall
  // back to the list element itself.
  get rowsContainer():HTMLElement {
    return this.hasRowsContainerElement ? this.rowsContainerElement! : this.element;
  }

  get listData():SortableListData {
    return sortableListData({
      type: this.typeValue,
      listId: this.hasIdValue ? this.idValue : null,
      dropPosition: this.dropPosition,
      rowsContainer: this.rowsContainer,
    });
  }

  private canDrop(data:Record<string|symbol, unknown>):boolean {
    const { root } = this;
    if (root == null || root.busy) {
      return false;
    }

    return isItemFromRoot(root.element, data) && data.type === this.acceptedTypeValue;
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
