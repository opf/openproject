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
  AfterViewInit,
  DestroyRef,
  Directive,
  ElementRef,
  inject,
  input,
  output,
} from '@angular/core';
import { type AutoScrollAllowedAxis } from 'core-common/drag-and-drop/auto-scroll';
import {
  createSortableRoot,
  type SortableDropTransaction,
  type SortableRoot,
} from 'core-common/drag-and-drop/sortable-lists-engine';
import { type Edge } from 'core-common/drag-and-drop/reorder';
// Type-only: a value import would create a circular module dependency, since
// `OpSortableListsListDirective` injects this directive at runtime.
import type { OpSortableListsListDirective } from './sortable-lists-list.directive';

export type SortableListsAxis = 'vertical'|'horizontal';

export interface SortableListsDropEvent {
  transactionId:string;
  sourceId:string;
  sourceListId:string;
  targetId:string|null;
  edge:Edge|null;
  complete(success:boolean):void;
}

export interface SortableListsRemovedEvent {
  transactionId:string;
  itemId:string;
  targetListId:string;
  completion:Promise<boolean>;
  finalize():void;
}

type CleanupFn = () => void;

let lastGeneratedId = 0;

function generateListId():string {
  lastGeneratedId += 1;
  return `op-sortable-list-${lastGeneratedId}`;
}

// The root of one drag-and-drop scope, thinly binding the shared sortable
// engine to Angular's view lifecycle; owns nothing about the consumer's data.
// With no explicit `opSortableListsList` child it behaves as a single
// implicit list (e.g. the draggable autocompleter) and fires its own proxy
// outputs; once an explicit list registers, that list's outputs take over —
// see `attachList`.
@Directive({
  selector: '[opSortableLists]',
})
export class OpSortableListsDirective implements AfterViewInit {
  private readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  private readonly destroyRef = inject(DestroyRef);

  axis = input<SortableListsAxis>('vertical', { alias: 'opSortableListsAxis' });

  // Autoscroll container for the collapsed (implicit-list) case — see
  // `registerImplicitList`. An explicit `opSortableListsList` child has its
  // own `opSortableListsListScrollContainer` input instead.
  scrollContainer = input<Element|null>(null, { alias: 'opSortableListsScrollContainer' });

  // Proxy outputs: statically declared so a template can always bind them,
  // but only emit while this root is acting as the implicit (collapsed)
  // list — see the class doc comment.
  opSortableListsDrop = output<SortableListsDropEvent>();

  opSortableListsRemoved = output<SortableListsRemovedEvent>();

  readonly implicitListId = generateListId();

  private readonly childLists = new Map<string, OpSortableListsListDirective>();

  private engineRoot:SortableRoot|null = null;

  private implicitListCleanup:CleanupFn|null = null;

  // Set before `engineRoot.destroy()` runs, so a teardown-order callback
  // still in flight (notably `attachList`'s cleanup below) knows to skip
  // resurrecting the implicit list rather than relying solely on the
  // engine's own post-destroy no-op.
  private destroying = false;

  ngAfterViewInit():void {
    // Guarantees the engine (and implicit list) exists even for a root that
    // never receives an item — an empty list must still be a valid drop
    // target. Idempotent: a nested item/list directive's earlier-running
    // `ngOnInit` may already have triggered it.
    this.getEngineRoot();
  }

  // Called by an explicit `opSortableListsList` child's `ngOnInit`. The first
  // explicit list retires the implicit list; the last to detach brings it back.
  attachList(list:OpSortableListsListDirective):CleanupFn {
    const engineRoot = this.getEngineRoot();

    if (this.childLists.size === 0) {
      this.unregisterImplicitList();
    }

    const listId = list.listId();
    this.childLists.set(listId, list);

    const cleanup = engineRoot.registerList({
      element: list.elementRef.nativeElement,
      listId,
      accepts: this.wrapAccepts(list.accepts()),
      scrollContainer: list.scrollContainer() ?? undefined,
    });

    return () => {
      cleanup();
      this.childLists.delete(listId);
      // Skip while mid-teardown: Angular's destroy order does not guarantee
      // this runs before the root's own `destroyRef.onDestroy` (see `destroying`).
      if (this.childLists.size === 0 && !this.destroying) {
        this.registerImplicitList();
      }
    };
  }

  // Internal API used by `OpSortableListsItemDirective`. Adapts the
  // consumer-facing no-argument `canDrag` to the engine's pointer-context
  // signature.
  registerItem(opts:{
    element:HTMLElement;
    itemId:string;
    listId:string;
    canDrag?:() => boolean;
  }):CleanupFn {
    const engineRoot = this.getEngineRoot();

    return engineRoot.registerItem({
      element: opts.element,
      itemId: opts.itemId,
      listId: opts.listId,
      canDrag: opts.canDrag ? () => opts.canDrag!() : undefined,
    });
  }

  // Public API for a consumer that needs an ADDITIONAL autoscroll container
  // beyond the collapsed/explicit-list resolution above — e.g. a board whose
  // scrollable viewport is neither the root nor an ancestor of it.
  addScrollContainer(element:Element, axis?:AutoScrollAllowedAxis):CleanupFn {
    return this.getEngineRoot().addScrollContainer(element, axis);
  }

  private getEngineRoot():SortableRoot {
    if (!this.engineRoot) {
      this.engineRoot = createSortableRoot({
        element: this.elementRef.nativeElement,
        axis: this.axis(),
        onDrop: (transaction) => this.dispatch(transaction),
      });
      this.destroyRef.onDestroy(() => {
        this.destroying = true;
        this.engineRoot?.destroy();
      });
      this.registerImplicitList();
    }

    return this.engineRoot;
  }

  private registerImplicitList():void {
    if (this.implicitListCleanup || !this.engineRoot) {
      return;
    }

    this.implicitListCleanup = this.engineRoot.registerList({
      element: this.elementRef.nativeElement,
      listId: this.implicitListId,
      scrollContainer: this.resolveScrollContainer(),
    });
  }

  private unregisterImplicitList():void {
    this.implicitListCleanup?.();
    this.implicitListCleanup = null;
  }

  // Collapsed (implicit-list) autoscroll target: explicit input wins, then
  // the nearest scrollable ancestor — a host with `overflow: visible` (e.g.
  // the draggable autocompleter) is not itself a valid scroll target and
  // Pragmatic would warn — else undefined, so the engine's own default applies.
  private resolveScrollContainer():Element|undefined {
    return this.scrollContainer() ?? this.closestScrollableAncestor() ?? undefined;
  }

  private closestScrollableAncestor():Element|null {
    let element:HTMLElement|null = this.elementRef.nativeElement;

    while (element) {
      const { overflowX, overflowY } = window.getComputedStyle(element);
      if (/(auto|scroll|overlay)/.test(overflowY + overflowX)) {
        return element;
      }
      element = element.parentElement;
    }

    return null;
  }

  private wrapAccepts(accepts:(() => boolean)|null):(() => boolean)|undefined {
    return accepts ? () => accepts() : undefined;
  }

  // Cross-list moves emit `removed` on the source list BEFORE `drop` on the
  // target, so a `removed` handler never sees the item still in the target's
  // rendered list. Same-list moves emit `drop` only.
  private dispatch(transaction:SortableDropTransaction):void {
    const { intent } = transaction;

    const drop:SortableListsDropEvent = {
      transactionId: transaction.id,
      sourceId: intent.sourceId,
      sourceListId: intent.sourceListId,
      targetId: intent.targetItemId,
      edge: intent.edge,
      complete: (success) => transaction.complete(success),
    };

    if (intent.sourceListId !== intent.targetListId) {
      const removed:SortableListsRemovedEvent = {
        transactionId: transaction.id,
        itemId: intent.sourceId,
        targetListId: intent.targetListId,
        completion: transaction.completion,
        finalize: () => transaction.finalize(),
      };
      this.emitRemoved(intent.sourceListId, removed);
    }

    this.emitDrop(intent.targetListId, drop);
  }

  private emitDrop(listId:string, event:SortableListsDropEvent):void {
    const list = this.childLists.get(listId);
    if (list) {
      list.opSortableListsDrop.emit(event);
    } else {
      this.opSortableListsDrop.emit(event);
    }
  }

  private emitRemoved(listId:string, event:SortableListsRemovedEvent):void {
    const list = this.childLists.get(listId);
    if (list) {
      list.opSortableListsRemoved.emit(event);
    } else {
      this.opSortableListsRemoved.emit(event);
    }
  }
}
