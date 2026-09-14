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

import { Injectable, OnDestroy } from '@angular/core';
import {
  createSortableRoot,
  type CleanupFn,
  type SortableDropTransaction,
  type SortableRoot,
} from 'core-common/drag-and-drop/sortable-lists-engine';
import { reorderById, type Edge } from 'core-common/drag-and-drop/reorder';

// Same selector the row/card markup has always relied on for drag rows —
// kept as the boundary between "draggable item" and structural children
// (group headers, the inline-create reference container, …).
const ROW_SELECTOR = ':scope > [data-work-package-id]';

export interface DragIntent {
  sourceId:string;
  targetId:string|null;
  edge:Edge|null;
}

export interface DragMember {
  dragContainer:HTMLElement;
  scrollContainers:HTMLElement[];
  /** Row → its stable id, or null if the row is not a draggable item. */
  itemIdOf(row:HTMLElement):string|null;
  /** Whether this row may be picked up; `handle` is the exact element under the pointer. */
  canPickup(row:HTMLElement, handle:HTMLElement|null):boolean;
  /** Whether this container currently accepts drops. */
  accepts():boolean;
  onDragStarted?(row:HTMLElement):void;
  onCancel?(row:HTMLElement):void;
  /**
   * Renders the native drag image's contents into `preview`, synchronously,
   * while Pragmatic captures it. When omitted, the row is cloned as-is; supply
   * this when the row only lays out correctly inside its own context (a table
   * row).
   */
  renderPreview?(row:HTMLElement, preview:HTMLElement):void;
  /** `targetId` null means "append at the end". Must settle `complete`. */
  onMoved(intent:DragIntent, complete:(success:boolean) => void):void;
}

interface Binding {
  member:DragMember;
  root:SortableRoot;
  listId:string;
  listCleanup:CleanupFn;
  observer:MutationObserver;
  rowCleanups:Map<HTMLElement, CleanupFn>;
}

let lastListId = 0;

function generateListId():string {
  lastListId += 1;
  return `wp-drag-and-drop-${lastListId}`;
}

// Thin binding of the shared sortable engine to the container-registration
// API this class has always exposed. One engine root per registered member —
// every consumer here drags within a single container, never across two, so
// isolated per-member scopes cost nothing.
@Injectable({ providedIn: 'root' })
export class DragAndDropService implements OnDestroy {
  private readonly bindings = new Map<HTMLElement, Binding>();

  ngOnDestroy():void {
    this.bindings.forEach((binding) => this.teardown(binding));
    this.bindings.clear();
  }

  public register(member:DragMember):void {
    const listId = generateListId();

    const root = createSortableRoot({
      element: member.dragContainer,
      axis: 'vertical',
      preview: ({ source, container }) => {
        // Pragmatic inline-styles its own container to reset the popover
        // user-agent defaults, which beats any stylesheet rule — so the
        // chrome goes on an element we own.
        const preview = document.createElement('div');
        preview.classList.add('op-drag-preview');
        container.appendChild(preview);

        if (member.renderPreview) {
          member.renderPreview(source.element, preview);
        } else {
          preview.appendChild(source.element.cloneNode(true));
        }
      },
      onDragStarted: (source) => member.onDragStarted?.(source.element),
      onCancel: (source) => member.onCancel?.(source.element),
      onDrop: (transaction) => this.handleDrop(member, transaction),
    });

    const listCleanup = root.registerList({
      element: member.dragContainer,
      listId,
      accepts: () => member.accepts(),
      scrollContainer: member.scrollContainers[0],
    });

    const binding:Binding = {
      member,
      root,
      listId,
      listCleanup,
      // Replaced synchronously below; MutationObserver has no no-op ctor.
      observer: null as unknown as MutationObserver,
      rowCleanups: new Map<HTMLElement, CleanupFn>(),
    };

    binding.observer = new MutationObserver(() => this.syncRows(binding));
    this.bindings.set(member.dragContainer, binding);

    this.syncRows(binding);
    // Direct children only. `syncRows` still FINDS rows nested in an
    // intermediate wrapper (it queries the subtree), but later mutations
    // inside that wrapper would never trigger a sync without `subtree: true`
    // — which observes every descendant change in the table.
    binding.observer.observe(member.dragContainer, { childList: true });

    // The primary scroll container is wired via registerList above; any
    // further ones (none of today's consumers pass more than one) are
    // additional autoscroll targets only.
    member.scrollContainers.slice(1).forEach((container) => root.addScrollContainer(container));
  }

  public remove(container:HTMLElement):void {
    const binding = this.bindings.get(container);
    if (!binding) {
      return;
    }

    this.teardown(binding);
    this.bindings.delete(container);
  }

  // Diffs the container's direct item rows against the tracked registrations —
  // called on register and on every subsequent childList mutation.
  private syncRows(binding:Binding):void {
    const {
      member, root, listId, rowCleanups,
    } = binding;
    const rows = new Set(Array.from(member.dragContainer.querySelectorAll<HTMLElement>(ROW_SELECTOR)));

    rowCleanups.forEach((cleanup, row) => {
      if (!rows.has(row)) {
        cleanup();
        rowCleanups.delete(row);
      }
    });

    rows.forEach((row) => {
      if (rowCleanups.has(row)) {
        return;
      }

      const itemId = member.itemIdOf(row);
      if (!itemId) {
        return;
      }

      rowCleanups.set(row, root.registerItem({
        element: row,
        itemId,
        listId,
        canDrag: ({ element, pointer }) => member.canPickup(element, this.handleUnderPointer(element, pointer)),
      }));
    });
  }

  // The exact element under the pointer, scoped to the row — the engine's own
  // canDrag wrapper already suppresses interactive descendants (buttons,
  // inputs, links) before this ever runs; a consumer's `canPickup` gates on
  // the result itself (e.g. requiring a specific handle class).
  private handleUnderPointer(row:HTMLElement, pointer:{ clientX:number; clientY:number }):HTMLElement|null {
    const target = row.ownerDocument.elementFromPoint(pointer.clientX, pointer.clientY);
    return target instanceof HTMLElement && row.contains(target) ? target : null;
  }

  private handleDrop(member:DragMember, transaction:SortableDropTransaction):void {
    const { intent } = transaction;
    const idOrder = this.rowIdOrder(member);

    const reordered = reorderById({
      list: idOrder,
      getId: (id) => id,
      sourceId: intent.sourceId,
      targetId: intent.targetItemId,
      closestEdge: intent.edge,
      axis: 'vertical',
    });

    // Genuine no-op (e.g. dropped back adjacent to its own original spot):
    // settle immediately without bothering the consumer.
    if (reordered === idOrder) {
      transaction.complete(true);
      return;
    }

    member.onMoved(
      { sourceId: intent.sourceId, targetId: intent.targetItemId, edge: intent.edge },
      (success) => transaction.complete(success),
    );
  }

  private rowIdOrder(member:DragMember):string[] {
    return Array
      .from(member.dragContainer.querySelectorAll<HTMLElement>(ROW_SELECTOR))
      .map((row) => member.itemIdOf(row))
      .filter((id):id is string => !!id);
  }

  private teardown(binding:Binding):void {
    binding.observer.disconnect();
    binding.rowCleanups.forEach((cleanup) => cleanup());
    binding.rowCleanups.clear();
    binding.listCleanup();
    binding.root.destroy();
  }
}
