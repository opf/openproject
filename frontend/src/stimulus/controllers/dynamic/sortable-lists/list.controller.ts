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
  canAccept,
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
  };

  declare readonly typeValue:string;
  declare readonly hasTypeValue:boolean;
  declare readonly idValue:string;
  declare readonly hasIdValue:boolean;
  declare readonly dropPositionValue:string;

  private root?:SortableListsRoot;
  private cleanupFn?:CleanupFn;

  connect():void {
    // A list without a type value is not a drop target.
    if (!this.hasTypeValue) {
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

  // Called by the root controller's outlet-connected callback.
  connectRoot(root:SortableListsRoot):void {
    this.root = root;
    this.reflectMoving(root.moving);
  }

  disconnectRoot():void {
    this.root = undefined;
    // The root only reaches still-connected list outlets when it ends a move, so
    // a list that disconnects mid-move would otherwise keep aria-busy forever.
    this.reflectMoving(false);
  }

  reflectMoving(moving:boolean):void {
    if (moving) {
      this.element.setAttribute('aria-busy', 'true');
    } else {
      this.element.removeAttribute('aria-busy');
    }
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
    const { root } = this;
    if (root == null || root.moving) {
      return false;
    }

    return canAccept(root, data);
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
