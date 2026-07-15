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

import {
  attachClosestEdge,
  type Edge,
  extractClosestEdge,
} from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';
import { combine } from '@atlaskit/pragmatic-drag-and-drop/combine';
import { draggable, dropTargetForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { preserveOffsetOnSource } from '@atlaskit/pragmatic-drag-and-drop/element/preserve-offset-on-source';
import { setCustomNativeDragPreview } from '@atlaskit/pragmatic-drag-and-drop/element/set-custom-native-drag-preview';
import { preventUnhandled } from '@atlaskit/pragmatic-drag-and-drop/prevent-unhandled';
import { type Input } from '@atlaskit/pragmatic-drag-and-drop/types';
import { Controller, type ActionEvent } from '@hotwired/stimulus';
import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import { closestInteractiveElement } from 'core-stimulus/helpers/interactive-element-helper';
import {
  isItemFromRoot,
  sortableItemData,
  type RootAwareChild,
  type SortableItemData,
  type SortableListsRoot,
} from './drag-and-drop';
import { isMoveDirection, sortableItemSelector } from './list-dom';
import { renderDragPreview } from './preview';

type CleanupFn = () => void;

export default class ItemController extends Controller<HTMLElement> implements RootAwareChild {
  static targets = ['handle', 'preview', 'moveItem', 'moveMenu'];
  static elements = { menu: 'action-menu' };

  static values = {
    id: String,
    type: String,
    hideUnavailable: { type: Boolean, default: true },
  };

  declare readonly idValue:string;
  declare readonly hasIdValue:boolean;
  declare readonly typeValue:string;
  declare readonly hasTypeValue:boolean;
  declare readonly hideUnavailableValue:boolean;

  declare readonly handleTarget:HTMLElement;
  declare readonly hasHandleTarget:boolean;
  declare readonly previewTarget:HTMLElement;
  declare readonly hasPreviewTarget:boolean;
  declare readonly moveItemTargets:HTMLElement[];
  declare readonly moveMenuTarget:HTMLElement;
  declare readonly hasMoveMenuTarget:boolean;

  // Provided by the stimulus-elements blessing; absent when the item is not
  // inside a Primer action-menu (a drag-only consumer), in which case the move
  // menu simply does nothing — drag behaviour is unaffected.
  declare readonly menuElement:ActionMenuElement;
  declare readonly hasMenuElement:boolean;

  private cleanupFn?:CleanupFn;
  private dropIndicatorElement?:HTMLElement;
  private root?:SortableListsRoot;

  private readonly onMenuToggle = (event:Event):void => {
    // The toggle event does not bubble, so listen in capture phase; recompute
    // availability whenever the card menu opens, since a reorder can have
    // shifted siblings meanwhile. Read newState by duck typing rather than
    // `instanceof ToggleEvent` so a browser without the ToggleEvent global
    // cannot throw.
    if ((event as ToggleEvent).newState === 'open') {
      this.refreshMoveMenuAvailability();
    }
  };

  connect():void {
    this.warnOnMissingValues();
    this.register();
    this.element.addEventListener('toggle', this.onMenuToggle, true);
  }

  disconnect():void {
    // A morph can remove a hovering row mid-drag; without this the drop indicator
    // it owns on a sibling row is never cleared (no onDrop fires, and no other
    // controller may clear a foreign owner), leaving a phantom drop line.
    this.clearDropIndicator();
    this.cleanupFn?.();
    this.cleanupFn = undefined;
    this.element.removeEventListener('toggle', this.onMenuToggle, true);
    this.disconnectRoot();
  }

  // A move item entering the DOM (inline or via a deferred fragment) triggers
  // an availability refresh here, but `this.root` is usually still unset at
  // this point (the outlet's connectRoot callback runs later), so this call
  // typically no-ops. The menu-open toggle handler is what actually
  // establishes correct availability, refreshing on every open once the root
  // is connected and after any reorder has shifted siblings. No
  // include-fragment knowledge, so both hooks work for any menu.
  moveItemTargetConnected():void {
    this.refreshMoveMenuAvailability();
  }

  move(event:ActionEvent):void {
    const item = event.currentTarget;
    if (!this.hasMenuElement || !(item instanceof HTMLElement)) {
      return;
    }

    if (this.menuElement.isItemDisabled(item) || this.menuElement.isItemHidden(item)) {
      return;
    }

    const { direction } = event.params;
    if (isMoveDirection(direction)) {
      this.root?.moveInDirection(this.element, direction);
    }
  }

  // Called by the root controller's outlet-connected callback.
  connectRoot(root:SortableListsRoot):void {
    this.root = root;
  }

  disconnectRoot():void {
    this.root = undefined;
  }

  // Re-establish the Pragmatic DnD registration from controller state. Called
  // by the root controller after a morph: a morph can leave an element carrying
  // Pragmatic's internal drop-target marker attribute without a live registry
  // entry, and Pragmatic silently aborts its drop-target search at such an
  // element — every row underneath it stops accepting drops.
  reregister():void {
    this.cleanupFn?.();
    this.register();
  }

  private register():void {
    this.cleanupFn = combine(
      this.registerDraggable(),
      this.registerDropTarget(),
    );
  }

  // Both values are required: an item with an empty id can never be persisted,
  // and an empty type never matches a list's accepted type, so the item would
  // appear draggable yet silently refuse every drop. Surface that wiring mistake.
  private warnOnMissingValues():void {
    if (!this.hasIdValue) {
      console.warn(
        'sortable-lists--item is missing its required id value (data-sortable-lists--item-id-value); it cannot be moved.',
        this.element,
      );
    }

    if (!this.hasTypeValue) {
      console.warn(
        'sortable-lists--item is missing its required type value (data-sortable-lists--item-type-value); it cannot be moved.',
        this.element,
      );
    }
  }

  private registerDraggable():CleanupFn {
    return draggable({
      element: this.element,
      ...(this.hasHandleTarget ? { dragHandle: this.handleTarget } : {}),
      canDrag: ({ input }) => {
        const { root } = this;
        if (root == null || root.busy) {
          return false;
        }
        return this.canDragFromPoint(input.clientX, input.clientY);
      },
      getInitialData: () => this.getItemData(),
      onDragStart: () => {
        preventUnhandled.start();
        this.element.setAttribute('data-dragging', 'source');
      },
      onDrop: () => {
        preventUnhandled.stop();
        this.clearDropIndicator();
        this.element.removeAttribute('data-dragging');
      },
      onGenerateDragPreview: ({ location, nativeSetDragImage }) => {
        if (!this.hasPreviewTarget) {
          return;
        }

        setCustomNativeDragPreview({
          nativeSetDragImage,
          getOffset: preserveOffsetOnSource({
            element: this.previewTarget,
            input: location.current.input,
          }),
          render: ({ container }) => renderDragPreview({
            previewTarget: this.previewTarget,
            sourceElement: this.element,
            container,
          }),
        });
      },
    });
  }

  private registerDropTarget():CleanupFn {
    return dropTargetForElements({
      element: this.element,
      canDrop: ({ source }) => {
        const { root } = this;
        if (root == null || root.busy) {
          return false;
        }

        // Same-type proxy: an item sits in a list, so its own type is one the
        // list accepts, and matching the dragged type against this item's type
        // needs no list lookup. This assumes every item's type is among its
        // list's accepted types; if a mixed-type list ever held an item of a
        // non-accepted type, this target would accept a drop the list rejects,
        // resolving to a silent no-op. Holds today (one type per list).
        return isItemFromRoot(root.element, source.data)
          && source.data.itemId !== this.idValue
          && source.data.type === this.typeValue;
      },
      getData: ({ input }) => {
        return attachClosestEdge(this.getItemData(), {
          element: this.element,
          input,
          allowedEdges: ['top', 'bottom'],
        });
      },
      getIsSticky: ({ input }) => this.isWithinRowsSpan(input),
      onDragEnter: ({ self }) => {
        const closestEdge = extractClosestEdge(self.data);
        this.renderDropIndicator(closestEdge);
      },
      onDrag: ({ self }) => {
        const closestEdge = extractClosestEdge(self.data);
        this.renderDropIndicator(closestEdge);
      },
      onDragLeave: () => {
        this.clearDropIndicator();
      },
      onDrop: () => {
        this.clearDropIndicator();
      },
    });
  }

  private canDragFromPoint(clientX:number, clientY:number):boolean {
    const target = this.element.ownerDocument.elementFromPoint(clientX, clientY);

    if (!(target instanceof Element) || !this.element.contains(target)) {
      return true;
    }

    const dragHandle = this.hasHandleTarget ? this.handleTarget : this.element;

    return closestInteractiveElement(target, dragHandle) == null;
  }

  // Stickiness bridges the gaps between rows so the drop indicator does not
  // flicker while the pointer crosses them. Above the first row (the list
  // header) or below the last row (empty space) the pointer has left the rows
  // region, and the list's configured drop position must take over, so the
  // sticky target lets go there. Rows are direct children of the rows
  // container, so the item's parent element is that container.
  private isWithinRowsSpan(input:Input):boolean {
    const rowsContainer = this.element.parentElement;
    const firstRow = rowsContainer?.firstElementChild;
    const lastRow = rowsContainer?.lastElementChild;

    if (!firstRow || !lastRow) {
      return false;
    }

    return input.clientY >= firstRow.getBoundingClientRect().top
      && input.clientY <= lastRow.getBoundingClientRect().bottom;
  }

  private getItemData():SortableItemData {
    return sortableItemData({
      itemId: this.idValue,
      type: this.typeValue,
      rootElement: this.root?.element ?? null,
    });
  }

  private renderDropIndicator(edge:Edge|null) {
    const currentEdge = this.dropIndicatorElement?.dataset.dropPosition;
    const currentOwner = this.dropIndicatorElement?.dataset.dropPositionOwner;
    const nextIndicator = edge ? this.resolveDropIndicator(edge) : null;

    if (
      currentOwner === this.idValue &&
      nextIndicator &&
      this.dropIndicatorElement === nextIndicator.element &&
      currentEdge === nextIndicator.edge
    ) {
      return;
    }

    this.clearDropIndicator();

    if (nextIndicator) {
      this.renderDropIndicatorOn(nextIndicator.element, nextIndicator.edge);
    }
  }

  private resolveDropIndicator(edge:Edge):{ element:HTMLElement; edge:Edge } {
    if (edge !== 'bottom') {
      return { element: this.element, edge };
    }

    const nextItem = this.element.nextElementSibling;

    if (
      nextItem instanceof HTMLElement &&
      nextItem.matches(sortableItemSelector) &&
      !nextItem.hasAttribute('data-dragging')
    ) {
      return { element: nextItem, edge: 'top' };
    }

    return { element: this.element, edge };
  }

  private renderDropIndicatorOn(element:HTMLElement, edge:Edge):void {
    this.dropIndicatorElement = element;
    element.dataset.dropPosition = edge;
    element.dataset.dropPositionOwner = this.idValue;
  }

  private clearDropIndicator() {
    if (!this.dropIndicatorElement) {
      return;
    }

    if (this.dropIndicatorElement.dataset.dropPositionOwner === this.idValue) {
      delete this.dropIndicatorElement.dataset.dropPosition;
      delete this.dropIndicatorElement.dataset.dropPositionOwner;
    }

    this.dropIndicatorElement = undefined;
  }

  private refreshMoveMenuAvailability():void {
    const root = this.root;
    if (!root || !this.hasMenuElement) {
      return;
    }

    // Null availability means the item is not in a list yet; leave the menu
    // alone until the outlet wiring settles.
    const availability = root.moveAvailability(this.element);
    if (!availability) {
      return;
    }

    let available = 0;
    for (const item of this.moveItemTargets) {
      // Outside a Stimulus action there is no event.params, so read the
      // param's backing attribute directly.
      const direction = item.getAttribute(`data-${this.identifier}-direction-param`);
      const enabled = isMoveDirection(direction) && availability[direction];
      this.setAvailability(item, enabled);
      if (enabled) {
        available += 1;
      }
    }

    if (this.hasMoveMenuTarget) {
      this.setAvailability(this.moveMenuTarget, available > 0);
    }
  }

  // Availability goes through the action-menu element's API: disableItem sets the
  // ActionListItem--disabled class plus aria-disabled on the item's content, and
  // hideItem toggles hidden. It operates on any descendant li, including the ones
  // in the nested move submenu. Default is hide; hideUnavailable=false switches to disable.
  private setAvailability(item:HTMLElement, available:boolean):void {
    const menu = this.menuElement;

    if (this.hideUnavailableValue) {
      if (available) {
        menu.showItem(item);
      } else {
        menu.hideItem(item);
      }
    } else if (available) {
      menu.enableItem(item);
    } else {
      menu.disableItem(item);
    }
  }
}
