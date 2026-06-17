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
import { Controller } from '@hotwired/stimulus';
import {
  canAccept,
  sortableListData,
  type RootAwareChild,
  type SortableListData,
  type SortableListsRoot,
} from './drag-and-drop';

type CleanupFn = () => void;

export default class ListController extends Controller<HTMLElement> implements RootAwareChild {
  static values = {
    type: String,
    id: String,
  };

  declare readonly typeValue:string;
  declare readonly hasTypeValue:boolean;
  declare readonly idValue:string;
  declare readonly hasIdValue:boolean;

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

  private get initialized():boolean {
    return this.root != null;
  }

  private get listData():SortableListData {
    return sortableListData({
      type: this.typeValue,
      listId: this.hasIdValue ? this.idValue : null,
    });
  }

  private canDrop(data:Record<string|symbol, unknown>):boolean {
    if (!this.initialized || this.root!.moving) {
      return false;
    }

    return canAccept(this.root!, data);
  }
}
