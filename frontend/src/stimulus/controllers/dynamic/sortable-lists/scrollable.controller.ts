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

import { autoScrollForElements } from '@atlaskit/pragmatic-drag-and-drop-auto-scroll/element';
import { Controller } from '@hotwired/stimulus';
import {
  isItemFromRoot,
  type RootAwareChild,
  type SortableListsRoot,
} from './drag-and-drop';

type CleanupFn = () => void;
type AutoScrollAllowedAxis = 'vertical'|'horizontal'|'all';
type AutoScrollMaxScrollSpeed = 'standard'|'fast';

const allowedAxes = new Set<string>(['vertical', 'horizontal', 'all']);
const maxScrollSpeeds = new Set<string>(['standard', 'fast']);

export default class ScrollableController extends Controller<HTMLElement> implements RootAwareChild {
  static values = {
    allowedAxis: { type: String, default: 'vertical' },
    maxScrollSpeed: { type: String, default: 'standard' },
  };

  declare readonly allowedAxisValue:string;
  declare readonly maxScrollSpeedValue:string;

  private cleanupFn?:CleanupFn;
  private root?:SortableListsRoot;

  connect():void {
    this.register();
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
    this.register();
  }

  private register():void {
    this.cleanupFn = autoScrollForElements({
      element: this.element,
      canScroll: ({ source }) => {
        const { root } = this;
        return root != null && isItemFromRoot(root.element, source.data);
      },
      getAllowedAxis: () => this.allowedAxis,
      getConfiguration: () => ({ maxScrollSpeed: this.maxScrollSpeed }),
    });
  }

  // Called by the root controller's outlet-connected callback.
  connectRoot(root:SortableListsRoot):void {
    this.root = root;
  }

  disconnectRoot():void {
    this.root = undefined;
  }

  private get allowedAxis():AutoScrollAllowedAxis {
    return allowedAxes.has(this.allowedAxisValue) ? this.allowedAxisValue as AutoScrollAllowedAxis : 'vertical';
  }

  private get maxScrollSpeed():AutoScrollMaxScrollSpeed {
    return maxScrollSpeeds.has(this.maxScrollSpeedValue) ? this.maxScrollSpeedValue as AutoScrollMaxScrollSpeed : 'standard';
  }
}
