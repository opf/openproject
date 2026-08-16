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
  attachClosestEdge,
  type Edge,
  extractClosestEdge,
} from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';
import { combine } from '@atlaskit/pragmatic-drag-and-drop/combine';
import { draggable, dropTargetForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { formatURLsForExternal } from '@atlaskit/pragmatic-drag-and-drop/element/format-urls-for-external';
import { preserveOffsetOnSource } from '@atlaskit/pragmatic-drag-and-drop/element/preserve-offset-on-source';
import { setCustomNativeDragPreview } from '@atlaskit/pragmatic-drag-and-drop/element/set-custom-native-drag-preview';
import { preventUnhandled } from '@atlaskit/pragmatic-drag-and-drop/prevent-unhandled';
import { type Input } from '@atlaskit/pragmatic-drag-and-drop/types';
import { Controller, type ActionEvent } from '@hotwired/stimulus';
import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import { closestDragBlockingElement } from 'core-stimulus/helpers/interactive-element-helper';
import {
  permittedDestinationsAllowDrop,
  isItemFromRoot,
  sortableItemData,
  sortableItemIdentity,
  type RootAwareChild,
  type SortableItemData,
  type SortableListsRoot,
} from './drag-and-drop';
import {
  isMoveDirection,
  isOrderableItem,
  itemMobility,
  resolveItemExternalUrl,
  resolveItemLabel,
  sortableItemSelector,
  type DestinationIdentity,
} from './list-dom';
import { renderDragPreview } from './preview';
import { scopeIds, type ActionScope } from './selection-orchestrator';

type CleanupFn = () => void;

function isDestinationIdentity(candidate:unknown):candidate is DestinationIdentity {
  if (typeof candidate !== 'object' || candidate === null) {
    return false;
  }

  return 'type' in candidate
    && 'id' in candidate
    && typeof candidate.type === 'string'
    && (typeof candidate.id === 'string' || candidate.id === null);
}

export default class ItemController extends Controller<HTMLElement> implements RootAwareChild {
  static targets = ['handle', 'preview', 'destinationItem', 'moveItem', 'moveMenu', 'moveDivider', 'focus'];
  static elements = { menu: 'action-menu' };

  static values = {
    id: String,
    type: String,
    externalUrl: String,
    hideUnavailable: { type: Boolean, default: true },
    // See ItemMobility in list-dom. A `confined` item is still a full drag
    // source; only the lists the batch's permitted set names accept it.
    mobility: { type: String, default: 'free' },
  };

  declare readonly idValue:string;
  declare readonly hasIdValue:boolean;
  declare readonly typeValue:string;
  declare readonly hasTypeValue:boolean;
  declare readonly externalUrlValue:string;
  declare readonly hasExternalUrlValue:boolean;
  declare readonly hideUnavailableValue:boolean;

  declare readonly handleTarget:HTMLElement;
  declare readonly hasHandleTarget:boolean;
  declare readonly previewTarget:HTMLElement;
  declare readonly hasPreviewTarget:boolean;
  declare readonly destinationItemTargets:HTMLElement[];
  declare readonly moveItemTargets:HTMLElement[];
  declare readonly moveMenuTarget:HTMLElement;
  declare readonly hasMoveMenuTarget:boolean;
  declare readonly moveDividerTarget:HTMLElement;
  declare readonly hasMoveDividerTarget:boolean;
  declare readonly focusTarget:HTMLElement;
  declare readonly hasFocusTarget:boolean;

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
      this.refreshActionAvailability();
    }
  };

  private readonly onContextualBeforeOpen = (event:Event):void => {
    const focusTarget = this.hasFocusTarget ? this.focusTarget : null;
    if (event.target === this.element || event.target === focusTarget) {
      this.prepareActionMenu();
    }
  };

  private readonly onMenuBeforeToggle = (event:Event):void => {
    if (
      (event as ToggleEvent).newState === 'open'
      && this.hasMenuElement
      && event.target === this.menuElement.popoverElement
    ) {
      this.prepareActionMenu();
    }
  };

  connect():void {
    this.warnOnMissingValues();
    this.register();
    this.element.addEventListener('contextual-action-menu:beforeOpen', this.onContextualBeforeOpen);
    this.element.addEventListener('beforetoggle', this.onMenuBeforeToggle, true);
    this.element.addEventListener('toggle', this.onMenuToggle, true);
  }

  disconnect():void {
    // A morph can remove a hovering row mid-drag; without this the drop indicator
    // it owns on a sibling row is never cleared (no onDrop fires, and no other
    // controller may clear a foreign owner), leaving a phantom drop line.
    this.clearDropIndicator();
    this.cleanupFn?.();
    this.cleanupFn = undefined;
    this.element.removeEventListener('contextual-action-menu:beforeOpen', this.onContextualBeforeOpen);
    this.element.removeEventListener('beforetoggle', this.onMenuBeforeToggle, true);
    this.element.removeEventListener('toggle', this.onMenuToggle, true);
    this.disconnectRoot();
  }

  // An action item entering the DOM (inline or via a deferred fragment)
  // triggers an availability refresh here, but `this.root` is usually unset at
  // this point (the outlet's connectRoot callback runs later), so this call
  // typically no-ops. The menu-open toggle handler is what actually
  // establishes correct availability, refreshing on every open once the root
  // is connected and after any reorder has shifted siblings. No
  // include-fragment knowledge, so both hooks work for any menu.
  moveItemTargetConnected():void {
    this.refreshActionAvailability();
  }

  destinationItemTargetConnected():void {
    this.refreshActionAvailability();
  }

  move(event:ActionEvent):void {
    const item = event.currentTarget;
    if (!isOrderableItem(this.element) || !this.hasMenuElement || !(item instanceof HTMLElement)) {
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

  prepareDialog(event:CustomEvent<{ form:HTMLFormElement|null }>):void {
    const root = this.root;
    if (!root || root.busy) {
      event.preventDefault();
      return;
    }

    const scope = root.selectForAction(this.element);
    const form = event.detail.form;
    if (!form || !scope || scope.kind === 'refused') {
      event.preventDefault();
      return;
    }

    form.querySelectorAll('[data-sortable-lists-generated-id]').forEach((input) => input.remove());
    scopeIds(scope).forEach((id) => {
      const input = form.ownerDocument.createElement('input');
      input.type = 'hidden';
      input.name = 'ids[]';
      input.value = id;
      input.dataset.sortableListsGeneratedId = '';
      form.append(input);
    });
  }

  moveToDestination(event:ActionEvent):void {
    const item = event.currentTarget;
    if (!this.hasMenuElement || !(item instanceof HTMLElement)) {
      return;
    }

    if (this.menuElement.isItemDisabled(item) || this.menuElement.isItemHidden(item)) {
      return;
    }

    const candidates = this.destinationCandidates(item);
    if (candidates.length === 1) {
      this.root?.moveToDestination(this.element, candidates[0]);
    }
  }

  // The focus host is the consumer's business: Backlogs puts the tab stop on
  // the card inside the row, another consumer may focus the row itself.
  focusItem():void {
    (this.hasFocusTarget ? this.focusTarget : this.element).focus();
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
      // A non-movable item registers no draggable but stays a drop target:
      // its movable neighbours still anchor on it.
      isOrderableItem(this.element) ? this.registerDraggable() : () => undefined,
      this.registerDropTarget(),
    );
  }

  // Both values are required: an item with an empty id can never be persisted,
  // and an empty type would never match a list's accepted type, so it could
  // neither be dropped nor anchor a drop. Surface that wiring mistake.
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
      // Native drag data for consumers outside this window (other browser
      // windows, editors, chat apps). Optional: items without an external
      // URL expose nothing, exactly as before.
      ...(this.hasExternalUrlValue && this.externalUrlValue !== '' ? {
        getInitialDataForExternal: () => this.externalDragData(),
      } : {}),
      canDrag: ({ input }) => {
        const { root } = this;
        if (root == null || root.busy || root.dragRefused(this.element)) {
          return false;
        }
        return this.canDragFromPoint(input.clientX, input.clientY);
      },
      getInitialData: () => this.getItemData(),
      onDragStart: () => {
        this.root?.markDragBatch();
        // Cancels drops landing outside registered drop targets. This also
        // guards the external data channel: a misdropped card carrying
        // text/uri-list would otherwise navigate the current tab to that URL.
        preventUnhandled.start();
        this.element.setAttribute('data-dragging', 'source');
      },
      onDrop: () => {
        preventUnhandled.stop();
        this.clearDropIndicator();
        this.element.removeAttribute('data-dragging');
      },
      onGenerateDragPreview: ({ location, nativeSetDragImage }) => {
        // Pragmatic dispatches this before onDragStart, so the batch has to
        // be frozen by the time the preview renders.
        const batchSize = this.root?.freezeDragBatch(this.element) ?? 1;

        if (!this.hasPreviewTarget) {
          return;
        }

        setCustomNativeDragPreview({
          nativeSetDragImage,
          // preserveOffsetOnSource assumes the card sits at the container's
          // origin, but a batch preview pads the container's top for the
          // badge overhang and shifts the card down by it. Measured off the
          // container, so the stylesheet stays the single source of the
          // geometry; a single-card preview measures 0.
          getOffset: (args) => {
            const offset = preserveOffsetOnSource({
              element: this.previewTarget,
              input: location.current.input,
            })(args);

            return {
              x: offset.x,
              // A detached container's computed style resolves empty.
              y: offset.y + (parseFloat(getComputedStyle(args.container).paddingTop) || 0),
            };
          },
          render: ({ container }) => renderDragPreview({
            previewTarget: this.previewTarget,
            sourceElement: this.element,
            container,
            batchSize,
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
          && source.data.type === this.typeValue
          && !this.element.hasAttribute('data-dragging')
          && permittedDestinationsAllowDrop(source.data, this.root?.ownerDestinationOf(this.element) ?? null);
      },
      // Only the identity a drop needs; the batch-aware fields are computed
      // for the dragged source alone.
      getData: ({ input }) => attachClosestEdge(
        sortableItemIdentity({ itemId: this.idValue, type: this.typeValue }),
        { element: this.element, input, allowedEdges: ['top', 'bottom'] },
      ),
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

    return closestDragBlockingElement(target, dragHandle) == null;
  }

  // Stickiness bridges the gaps between rows so the drop indicator does not
  // flicker while the pointer crosses them. Above the first row (the list
  // header) or below the last row (empty space) the pointer has left the rows
  // region, and the list's configured drop position must take over, so the
  // sticky target lets go there. Rows are direct children of the owning
  // list's rows container, resolved through the root; the item's own parent
  // element is only a fallback for a rootless item (not yet wired to one).
  private isWithinRowsSpan(input:Input):boolean {
    const rowsContainer = this.root?.ownerRowsContainer(this.element) ?? this.element.parentElement;
    const firstRow = rowsContainer?.firstElementChild;
    const lastRow = rowsContainer?.lastElementChild;

    if (!firstRow || !lastRow) {
      return false;
    }

    return input.clientY >= firstRow.getBoundingClientRect().top
      && input.clientY <= lastRow.getBoundingClientRect().bottom;
  }

  // Every member of the prospective batch, so an external drop receives the
  // whole block; text/html joins in as one link per labelled member.
  private externalDragData():Record<string, string> {
    const members = this.root?.externalDragItems(this.element) ?? [this.element];
    const entries = members
      .map((member) => ({ url: resolveItemExternalUrl(member), label: resolveItemLabel(member) }))
      .filter((entry):entry is { url:string; label:string|null } => entry.url !== null);
    const urls = entries.map((entry) => entry.url);
    const data:Record<string, string> = {
      'text/uri-list': formatURLsForExternal(urls),
      'text/plain': urls.join('\n'),
    };

    const links = entries.filter((entry) => entry.label).map((entry) => {
      const anchor = this.element.ownerDocument.createElement('a');
      anchor.href = entry.url;
      anchor.textContent = entry.label;
      return anchor.outerHTML;
    });
    if (links.length > 0) {
      data['text/html'] = links.join('<br>');
    }

    return data;
  }

  private getItemData():SortableItemData {
    return sortableItemData({
      itemId: this.idValue,
      type: this.typeValue,
      rootElement: this.root?.element ?? null,
      // A rootless item can carry no batch, so its own mobility is the
      // whole answer, and it can name no list either: anything short of free
      // movement leaves it accepting nothing.
      permittedDestinations: this.root
        ? this.root.dragPermittedDestinations(this.element)
        : (itemMobility(this.element) === 'free' ? null : []),
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

    let next = this.element.nextElementSibling;
    while (next instanceof HTMLElement && next.matches(sortableItemSelector) && next.hasAttribute('data-dragging')) {
      next = next.nextElementSibling;
    }

    if (next instanceof HTMLElement && next.matches(sortableItemSelector)) {
      return { element: next, edge: 'top' };
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

  private prepareActionMenu():void {
    const scope = this.root?.selectForAction(this.element);
    if (scope) {
      this.refreshActionAvailability(scope);
    }
  }

  private refreshActionAvailability(preparedScope?:ActionScope):void {
    const root = this.root;
    if (!root || !this.hasMenuElement) {
      return;
    }

    const scope = preparedScope ?? root.actionScopeFor(this.element);
    this.refreshDestinationAvailability(root, scope);
    this.refreshMoveMenuAvailability(root);
    this.refreshMoveDivider();
  }

  private refreshDestinationAvailability(root:SortableListsRoot, scope:ActionScope):void {
    for (const item of this.destinationItemTargets) {
      const candidates = this.destinationCandidates(item);
      this.setAvailability(item, candidates.length > 0 && root.availableDestinations(scope, candidates).length > 0);
    }
  }

  private destinationCandidates(item:HTMLElement):DestinationIdentity[] {
    try {
      const candidates:unknown = JSON.parse(item.dataset.sortableListsDestinations ?? '');
      if (!Array.isArray(candidates)) {
        return [];
      }

      const destinations = candidates.filter(isDestinationIdentity);
      return destinations.length === candidates.length ? destinations : [];
    } catch {
      return [];
    }
  }

  private refreshMoveMenuAvailability(root:SortableListsRoot):void {
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

  // The divider that opens the move group is rendered server-side from a
  // permission check alone, so hiding the last entry below it would otherwise
  // leave a separator with nothing to separate. It never goes through
  // setAvailability: `disableItem` writes to the item's `.ActionListContent`,
  // which a divider does not have — and in that mode the group stays visible
  // anyway, only disabled.
  private refreshMoveDivider():void {
    if (!this.hasMoveDividerTarget || !this.hideUnavailableValue) {
      return;
    }

    const divider = this.moveDividerTarget;
    let sibling = divider.nextElementSibling;

    while (sibling) {
      if (!sibling.hasAttribute('hidden')) {
        divider.removeAttribute('hidden');
        return;
      }

      sibling = sibling.nextElementSibling;
    }

    divider.setAttribute('hidden', 'hidden');
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
