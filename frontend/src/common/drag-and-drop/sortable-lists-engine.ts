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
  draggable,
  dropTargetForElements,
  monitorForElements,
} from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { combine } from '@atlaskit/pragmatic-drag-and-drop/combine';
import { preserveOffsetOnSource } from '@atlaskit/pragmatic-drag-and-drop/element/preserve-offset-on-source';
import { setCustomNativeDragPreview } from '@atlaskit/pragmatic-drag-and-drop/element/set-custom-native-drag-preview';
import { preventUnhandled } from '@atlaskit/pragmatic-drag-and-drop/prevent-unhandled';
import type { Input } from '@atlaskit/pragmatic-drag-and-drop/types';
import { registerAutoScroll, type AutoScrollAllowedAxis } from 'core-common/drag-and-drop/auto-scroll';
import { clearDropIndicator, renderDropIndicator } from 'core-common/drag-and-drop/drop-indicator';
import { createSortableItemPayloadScope, type SortableItemData } from 'core-common/drag-and-drop/payload';
import {
  attachClosestEdge,
  extractClosestEdge,
  type Edge,
  type SortableAxis,
} from 'core-common/drag-and-drop/reorder';
import { closestDragBlockingElement } from 'core-common/interactive-element-helper';

export type CleanupFn = () => void;

export interface SortableSource {
  itemId:string;
  listId:string;
  element:HTMLElement;
}

export interface SortableDropIntent {
  sourceId:string;
  sourceListId:string;
  targetListId:string;
  targetItemId:string|null;   // null = container drop → append
  edge:Edge|null;
  axis:SortableAxis;          // the root's placement axis, captured at creation
}

export interface SortableDropTransaction {
  id:string;
  intent:SortableDropIntent;
  complete(success:boolean):void;   // idempotent; resolves after onDrop returns
  completion:Promise<boolean>;
  finalize():void;                  // idempotent; source-side settlement
}

export type PreviewFactory = (args:{
  source:SortableSource;
  container:HTMLElement;
}) => CleanupFn|void;

export interface SortableRootOptions {
  element:HTMLElement;
  axis?:SortableAxis;               // default 'vertical'
  // Independent from the placement axis above: a wrapped-grid root can place
  // items horizontally while still only auto-scrolling its vertical page
  // scroller. Defaults to the placement axis when unset.
  autoScrollAxis?:AutoScrollAllowedAxis;
  preview?:'native'|PreviewFactory; // default 'native'
  onDragStarted?:(source:SortableSource) => void;
  onCancel?:(source:SortableSource) => void;
  onDrop:(transaction:SortableDropTransaction) => void;
}

export interface SortableRoot {
  registerList(opts:{
    element:HTMLElement;
    listId:string;
    accepts?:(args:{ source:SortableSource }) => boolean;
    scrollContainer?:Element;
  }):CleanupFn;
  registerItem(opts:{
    element:HTMLElement;
    itemId:string;
    listId:string;
    canDrag?:(args:{ element:HTMLElement; pointer:{ clientX:number; clientY:number } }) => boolean;
  }):CleanupFn;
  addScrollContainer(element:Element, axis?:AutoScrollAllowedAxis):CleanupFn;
  destroy():void;
}

function allowedEdgesForAxis(axis:SortableAxis):Edge[] {
  return axis === 'horizontal' ? ['left', 'right'] : ['top', 'bottom'];
}

interface ItemsRow {
  left:number;
  right:number;
  top:number;
  bottom:number;
}

/** A list's vertical extent, plus the horizontal extent of each visual row within it. */
interface ItemsSpan {
  top:number;
  bottom:number;
  rows:ItemsRow[];
}

export function createSortableRoot(options:SortableRootOptions):SortableRoot {
  const axis = options.axis ?? 'vertical';
  const allowedEdges = allowedEdgesForAxis(axis);
  const autoScrollAxis = options.autoScrollAxis ?? axis;
  const scope = createSortableItemPayloadScope();
  const listDataKey = Symbol('op-sortable-list');
  const lists = new Map<string, { element:HTMLElement; accepts?:(args:{ source:SortableSource }) => boolean }>();
  // Registered item elements per list, for the bounded-stickiness row spans
  // below. Insertion order is irrelevant — the rows are grouped geometrically.
  const listItems = new Map<string, Set<HTMLElement>>();
  let transactionCounter = 0;
  let destroyed = false;
  const cleanups:CleanupFn[] = [];

  // Autoscroll registrations of this root, deduplicated per element:
  // Pragmatic's own registry is keyed by element and last-write-wins, so two
  // live registrations on one element (e.g. a board container that is both
  // the implicit list's closest scrollable ancestor and an explicit extra
  // scroll container) would first warn, then silently lose autoscroll for
  // the survivor once either side cleans up. Axes merge to 'all' when
  // registrants disagree; a release never narrows the axis back down — a
  // broader-than-needed allowance is harmless, a re-registration is not free.
  const scrollRegistrations = new Map<Element, { axes:AutoScrollAllowedAxis[]; cleanup:CleanupFn }>();

  const unionAxis = (axes:AutoScrollAllowedAxis[]):AutoScrollAllowedAxis => (
    axes.every((a) => a === axes[0]) ? axes[0] : 'all'
  );

  const acquireAutoScroll = (element:Element, axis:AutoScrollAllowedAxis):CleanupFn => {
    const register = (axes:AutoScrollAllowedAxis[]):CleanupFn => registerAutoScroll({
      element,
      canScroll: ({ source }) => scope.isItemData(source.data),
      axis: unionAxis(axes),
    });

    const existing = scrollRegistrations.get(element);
    if (existing) {
      const axisBefore = unionAxis(existing.axes);
      existing.axes.push(axis);
      if (unionAxis(existing.axes) !== axisBefore) {
        existing.cleanup();
        existing.cleanup = register(existing.axes);
      }
    } else {
      scrollRegistrations.set(element, { axes: [axis], cleanup: register([axis]) });
    }

    let released = false;
    return () => {
      if (released) {
        return;
      }
      released = true;

      const registration = scrollRegistrations.get(element);
      if (!registration) {
        return;
      }
      const index = registration.axes.indexOf(axis);
      if (index !== -1) {
        registration.axes.splice(index, 1);
      }
      if (registration.axes.length === 0) {
        registration.cleanup();
        scrollRegistrations.delete(element);
      }
    };
  };

  // Registers `fn` for `destroy()`; the returned handle deregisters itself
  // too, so a caller-invoked cleanup never double-runs.
  const track = (fn:CleanupFn):CleanupFn => {
    let done = false;
    const wrapped = ():void => {
      if (done) {
        return;
      }
      done = true;
      const index = cleanups.indexOf(wrapped);
      if (index !== -1) {
        cleanups.splice(index, 1);
      }
      fn();
    };
    cleanups.push(wrapped);
    return wrapped;
  };

  const isListData = (data:Record<string|symbol, unknown>):data is { listId:string } =>
    data[listDataKey] === true && typeof data.listId === 'string';

  const sourceOf = (data:SortableItemData, element:Element):SortableSource => ({
    itemId: data.itemId, listId: data.listId, element: element as HTMLElement,
  });

  // Busy = a transaction is in flight and not yet settled; blocks any
  // further drag so a second drop can never race the first (spec §A).
  const isBusy = ():boolean => options.element.hasAttribute('data-sortable-lists-busy');
  const setBusy = (busy:boolean):void => {
    if (busy) {
      options.element.setAttribute('data-sortable-lists-busy', 'true');
    } else {
      options.element.removeAttribute('data-sortable-lists-busy');
    }
  };

  // `accepts` gates EVERY drop into this list, including same-list reorders —
  // a list may allow dragging its own items OUT while still rejecting drops
  // back into itself (e.g. a filtered/read-only view). No same-list carve-out.
  const admits = (
    accepts:((args:{ source:SortableSource }) => boolean)|undefined,
    data:SortableItemData,
    element:Element,
  ):boolean => !accepts || accepts({ source: sourceOf(data, element) });

  // Bounded stickiness (spec §item→list handoff): an item target holds
  // selection via `getIsSticky` while the pointer is within the CURRENT span
  // of its list's items, over BOTH axes — a root-axis-only bound would
  // misread cross-axis blank space on a wrapped row as "within span".
  //
  // The vertical bound is the whole list, so the gaps between wrapped rows
  // stay covered; the horizontal bound belongs to the row the pointer is in,
  // so the empty tail of an incomplete row (a grid track with no card in it)
  // hands off to the list and appends. Recomputed geometrically, not by
  // registration order (a stable `@for` track reorders DOM without re-running
  // `ngOnInit`), and cached per animation frame.
  let frameCacheToken:number|null = null;
  const spanCache = new Map<string, ItemsSpan|null>();

  const clearFrameCache = ():void => {
    frameCacheToken = null;
    spanCache.clear();
  };

  const itemsSpanOfList = (listId:string):ItemsSpan|null => {
    frameCacheToken ??= requestAnimationFrame(clearFrameCache);
    if (spanCache.has(listId)) {
      return spanCache.get(listId) ?? null;
    }

    const rects:DOMRect[] = [];
    listItems.get(listId)?.forEach((element) => {
      const rect = element.getBoundingClientRect();
      // A hidden item measures 0×0 at the viewport origin and would drag the
      // span up there with it.
      if (rect.width > 0 && rect.height > 0) {
        rects.push(rect);
      }
    });

    if (rects.length === 0) {
      spanCache.set(listId, null);
      return null;
    }

    // Rects that overlap vertically are one visual row. Sorting by top edge
    // makes a single pass enough to group them.
    rects.sort((a, b) => a.top - b.top);
    const rows:ItemsRow[] = [];
    rects.forEach((rect) => {
      const row = rows[rows.length - 1];
      if (row && rect.top < row.bottom) {
        row.bottom = Math.max(row.bottom, rect.bottom);
        row.left = Math.min(row.left, rect.left);
        row.right = Math.max(row.right, rect.right);
        return;
      }

      rows.push({
        top: rect.top, bottom: rect.bottom, left: rect.left, right: rect.right,
      });
    });

    const span:ItemsSpan = {
      top: rows[0].top,
      bottom: Math.max(...rows.map((row) => row.bottom)),
      rows,
    };
    spanCache.set(listId, span);
    return span;
  };

  /** 0 while `clientY` is inside the row's band, otherwise the distance to it. */
  const distanceToRow = (row:ItemsRow, clientY:number):number => Math.max(row.top - clientY, clientY - row.bottom, 0);

  const withinItemsSpan = (input:{ clientX:number; clientY:number }, listId:string):boolean => {
    const span = itemsSpanOfList(listId);
    if (!span || input.clientY < span.top || input.clientY > span.bottom) {
      return false;
    }

    // Nearest, not containing: between two rows the pointer is in neither.
    const row = span.rows.reduce((closest, candidate) => (
      distanceToRow(candidate, input.clientY) < distanceToRow(closest, input.clientY) ? candidate : closest
    ));

    return input.clientX >= row.left && input.clientX <= row.right;
  };

  const createTransaction = (intent:SortableDropIntent):SortableDropTransaction => {
    transactionCounter += 1;
    const id = `op-sortable-txn-${transactionCounter}`;
    // Same-list moves have no separate source to settle, so completing the
    // target side is enough — a caller that never calls `finalize()` here
    // must not leave the root stuck busy.
    const sameList = intent.sourceListId === intent.targetListId;
    let completed = false;
    let finalized = false;
    let resolveCompletion!:(success:boolean) => void;
    const completion = new Promise<boolean>((resolve) => {
      resolveCompletion = resolve;
    });

    setBusy(true);
    const diagnostic = window.setTimeout(() => {
      console.warn(`Sortable transaction ${id} neither completed nor finalized after 10s.`);
    }, 10_000);
    // Tracked so `destroy()` cancels a still-pending diagnostic (e.g. the
    // consumer navigates away mid-drop) instead of leaking a timer that
    // outlives the root.
    const clearDiagnostic = track(() => window.clearTimeout(diagnostic));

    const trySettle = ():void => {
      if (completed && (finalized || sameList)) {
        clearDiagnostic();
        setBusy(false);
      }
    };

    return {
      id,
      intent,
      completion,
      complete(success:boolean):void {
        if (completed) {
          return;
        }
        completed = true;
        // Deferred so a synchronous `complete()` call inside the consumer's
        // `onDrop` cannot outrun that same callback's own emissions.
        queueMicrotask(() => {
          resolveCompletion(success);
          trySettle();
        });
      },
      finalize():void {
        if (finalized) {
          return;
        }
        finalized = true;
        queueMicrotask(trySettle);
      },
    };
  };

  // Root monitor: THE single drop-resolution point (spec §A). Tracked so
  // `destroy()` stays uniform and never re-invokes it.
  track(monitorForElements({
    canMonitor: ({ source }) => !isBusy() && scope.isItemData(source.data),
    onDrop: ({ source, location }) => {
      preventUnhandled.stop();
      delete source.element.dataset.dragging;

      const data = source.data as SortableItemData;
      const src = sourceOf(data, source.element);
      const targets = location.current.dropTargets;
      const itemTarget = targets.find((t) => scope.isItemData(t.data));
      const listTarget = targets.find((t) => isListData(t.data));

      if (!itemTarget && !listTarget) {
        options.onCancel?.(src);          // outside every registered list
        return;
      }

      const targetItemData = itemTarget?.data as SortableItemData|undefined;
      if (targetItemData?.itemId === data.itemId
          && targetItemData?.listId === data.listId) {
        return;                           // self-drop: no intent
      }

      const intent:SortableDropIntent = {
        sourceId: data.itemId,
        sourceListId: data.listId,
        targetListId: targetItemData?.listId
          ?? (listTarget!.data as unknown as { listId:string }).listId,
        targetItemId: targetItemData?.itemId ?? null,
        edge: itemTarget ? extractClosestEdge(itemTarget.data) : null,
        axis,
      };
      options.onDrop(createTransaction(intent));
    },
  }));

  return {
    registerList({
      element, listId, accepts, scrollContainer,
    }):CleanupFn {
      // Angular's teardown order can call this after the root is already
      // destroyed; a no-op is safer than throwing (matches `registerItem`/
      // `addScrollContainer` below).
      if (destroyed) {
        return () => undefined;
      }

      lists.set(listId, { element, accepts });

      const clearContainerIndicator = ():void => {
        delete element.dataset.dropContainer;
      };

      const syncContainerIndicator = ({ location }:{ location:{ current:{ dropTargets:{ element:Element }[] } } }):void => {
        if (location.current.dropTargets[0]?.element === element) {
          element.dataset.dropContainer = 'active';
        } else {
          clearContainerIndicator();
        }
      };

      const dropTargetCleanup = dropTargetForElements({
        element,
        getData: () => ({ [listDataKey]: true, listId }),
        canDrop: ({ source }) => !isBusy()
          && scope.isItemData(source.data)
          && admits(accepts, source.data, source.element),
        getIsSticky: () => false,
        onDragEnter: syncContainerIndicator,
        onDrag: syncContainerIndicator,
        onDragLeave: clearContainerIndicator,
        onDrop: clearContainerIndicator,
      });

      const autoScrollCleanup = acquireAutoScroll(scrollContainer ?? element, autoScrollAxis);

      return track(combine(dropTargetCleanup, autoScrollCleanup, () => {
        lists.delete(listId);
        clearContainerIndicator();
      }));
    },

    registerItem({
      element, itemId, listId, canDrag,
    }):CleanupFn {
      // See the matching guard in `registerList` above.
      if (destroyed) {
        return () => undefined;
      }

      const clearIndicator = ():void => clearDropIndicator(element, itemId);

      // The item accepts itself as a drop target (see canDrop below) so the
      // root monitor can resolve "self-drop, no intent" vs. "no item target,
      // fall through to container append" — but the indicator must still
      // never draw on the row being dragged, so suppression lives here, not
      // in canDrop.
      const isSelfSource = (data:Record<string|symbol, unknown>):boolean =>
        scope.isItemData(data) && data.itemId === itemId && data.listId === listId;

      const itemsForList = listItems.get(listId) ?? new Set<HTMLElement>();
      itemsForList.add(element);
      listItems.set(listId, itemsForList);

      const draggableCleanup = draggable({
        element,
        // Interactive-descendant suppression composes before the consumer's
        // own `canDrag`: a pointer over a button/input/link inside the row
        // must never start a drag, so that descendant keeps native behavior.
        canDrag: ({ input }) => {
          if (isBusy()) {
            return false;
          }
          const target = element.ownerDocument.elementFromPoint(input.clientX, input.clientY);
          if (target instanceof Element && element.contains(target)
              && closestDragBlockingElement(target, element) !== null) {
            return false;
          }
          return canDrag ? canDrag({ element, pointer: { clientX: input.clientX, clientY: input.clientY } }) : true;
        },
        getInitialData: () => scope.itemData(itemId, listId),
        onDragStart: () => {
          preventUnhandled.start();
          element.dataset.dragging = 'source';
          options.onDragStarted?.({ itemId, listId, element });
        },
        // Only wired when the consumer supplies a factory; 'native' (or the
        // unset default) leaves Pragmatic's own browser-native preview alone.
        ...(typeof options.preview === 'function' ? {
          onGenerateDragPreview: ({ nativeSetDragImage, source, location }:{
            nativeSetDragImage:DataTransfer['setDragImage']|null;
            source:{ element:Element; data:Record<string|symbol, unknown> };
            location:{ current:{ input:Input } };
          }) => {
            const factory = options.preview as PreviewFactory;
            setCustomNativeDragPreview({
              nativeSetDragImage,
              // Keep the pointer where it was pressed, rather than snapping
              // the preview's top-left corner under it.
              getOffset: preserveOffsetOnSource({
                element: source.element as HTMLElement,
                input: location.current.input,
              }),
              render: ({ container }) => factory({
                source: sourceOf(source.data as SortableItemData, source.element),
                container,
              }) ?? undefined,
            });
          },
        } : {}),
      });

      // No same-item exclusion here: registering as its own drop target lets
      // the root monitor's self-drop check (not this canDrop) resolve it as
      // the item target and no-op, rather than falling through to the
      // list's container-append target.
      const dropTargetCleanup = dropTargetForElements({
        element,
        canDrop: ({ source }) => {
          if (isBusy() || !scope.isItemData(source.data)) {
            return false;
          }
          const list = lists.get(listId);
          return admits(list?.accepts, source.data, source.element);
        },
        getData: ({ input }) => attachClosestEdge(scope.itemData(itemId, listId), {
          element,
          input,
          allowedEdges,
        }),
        // Bounded stickiness — see `withinItemsSpan` above.
        getIsSticky: ({ input }) => withinItemsSpan({ clientX: input.clientX, clientY: input.clientY }, listId),
        onDragEnter: ({ source, self }) => (
          isSelfSource(source.data) ? clearIndicator() : renderDropIndicator(element, extractClosestEdge(self.data), itemId)
        ),
        onDrag: ({ source, self }) => (
          isSelfSource(source.data) ? clearIndicator() : renderDropIndicator(element, extractClosestEdge(self.data), itemId)
        ),
        onDragLeave: clearIndicator,
        onDrop: clearIndicator,
      });

      return track(combine(draggableCleanup, dropTargetCleanup, () => {
        delete element.dataset.dragging;
        clearIndicator();
        itemsForList.delete(element);
      }));
    },

    addScrollContainer(element:Element, scrollAxis:AutoScrollAllowedAxis = 'all'):CleanupFn {
      // See the matching guard in `registerList` above.
      if (destroyed) {
        return () => undefined;
      }

      return track(acquireAutoScroll(element, scrollAxis));
    },

    destroy():void {
      if (destroyed) {
        return;
      }
      destroyed = true;
      [...cleanups].forEach((fn) => fn());
      lists.clear();
      listItems.clear();
      scrollRegistrations.clear();
      if (frameCacheToken !== null) {
        cancelAnimationFrame(frameCacheToken);
        clearFrameCache();
      }
      // Balances an in-flight drag's `preventUnhandled.start()`, whose
      // matching `stop()` can never run once the monitor is torn down mid-drag.
      preventUnhandled.stop();
      // The busy flag lives on the DOM element, not this closure, so it must
      // be cleared explicitly or a fresh engine reusing the same element
      // (e.g. Angular recreating the directive) would start out stuck busy.
      options.element.removeAttribute('data-sortable-lists-busy');
    },
  };
}
