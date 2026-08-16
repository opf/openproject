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
  monitorForElements,
  type ElementEventPayloadMap,
} from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { Controller } from '@hotwired/stimulus';
import { FetchRequest } from '@rails/request.js';
import { announce } from '@primer/live-region-element';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { OPToastEvent } from 'core-app/shared/components/toaster/toast-event';
import { flipMove } from 'core-stimulus/helpers/flip-helper';
import { performTurboStreamRequest } from 'core-stimulus/helpers/request-helpers';
import { parseTemplate } from 'url-template';
import {
  buildMoveFormData,
  isItemFromRoot,
  resolveDropIntent,
  singleItemBatch,
  type RootAwareChild,
  type SortableListData,
  type SortableListsRoot,
} from './sortable-lists/drag-and-drop';
import { selectionKey, type SelectionItem, type SelectionKey } from 'core-common/batch-selection';
import {
  captureRowPositions,
  isOrderableItem,
  itemAcceptsDestination,
  reorderRows,
  resolveBlockMove,
  resolveBlockMoveAvailability,
  resolveDirectionalPreviousItemId,
  resolveItemId,
  resolveItemLabel,
  resolveItemPosition,
  resolveItemType,
  restoreRowPositions,
  rowOf,
  rowsRemainAt,
  permittedDestinations,
  sameDestination,
  sortableListsBusyAttribute,
  type DestinationIdentity,
  type MoveAvailability,
  type MoveDirection,
} from './sortable-lists/list-dom';
import { SelectionOrchestrator, scopeIds, type ActionScope, type SelectionHost } from './sortable-lists/selection-orchestrator';
import { itemIdentity, orderedItemElements } from './sortable-lists/selection';

type CleanupFn = () => void;
type ElementDropPayload = ElementEventPayloadMap['onDrop'];
type MoveResult = { ok:true }|{ ok:false; showToast:boolean };
interface MoveAnnouncementContext { label:string|null; listName:string|null; crossList:boolean }

// Reduced to a same-origin relative URL: an absolute or foreign-origin
// template would otherwise be submitted as given.
function relativeUrl(url:URL):string {
  return `${url.pathname}${url.search}${url.hash}`;
}

export default class SortableListsController extends Controller<HTMLElement> implements SortableListsRoot, SelectionHost {
  static outlets = ['sortable-lists--list', 'sortable-lists--item', 'sortable-lists--scrollable'];

  static values = {
    moveUrlTemplate: String,
    moveUrlTemplates: Object,
    collectionMoveUrl: String,
    optimistic: { type: Boolean, default: false },
    selectionEnabled: { type: Boolean, default: false },
    announcementScope: { type: String, default: 'js.sortable_lists.selection' },
    moveAnnouncementScope: { type: String, default: 'js.sortable_lists.announcements' },
    selectionDescriptionId: { type: String, default: '' },
    maxBatchSize: { type: Number, default: 0 },
  };

  declare readonly sortableListsListOutlets:import('./sortable-lists/list.controller').default[];
  declare readonly sortableListsItemOutlets:(RootAwareChild & { focusItem():void })[];
  declare readonly sortableListsScrollableOutlets:RootAwareChild[];

  declare readonly moveUrlTemplateValue:string;
  declare readonly hasMoveUrlTemplateValue:boolean;
  declare readonly moveUrlTemplatesValue:Record<string, string>;
  declare readonly hasMoveUrlTemplatesValue:boolean;
  declare readonly collectionMoveUrlValue:string;
  declare readonly hasCollectionMoveUrlValue:boolean;
  declare readonly optimisticValue:boolean;
  declare readonly selectionEnabledValue:boolean;
  declare readonly announcementScopeValue:string;
  declare readonly moveAnnouncementScopeValue:string;
  declare readonly selectionDescriptionIdValue:string;
  declare readonly maxBatchSizeValue:number;

  private selection?:SelectionOrchestrator;

  private monitorCleanupFn?:CleanupFn;
  private healScheduled = false;
  private reconcileScheduled = false;
  private inFlightMoveRequests = 0;

  connect():void {
    // Busy belongs to in-flight controller work, not to cached DOM markup.
    // Reconnecting before settlement keeps the root blocked; reconnecting a
    // stale cached root after settlement clears the marker.
    this.syncBusyState();
    this.monitorCleanupFn = monitorForElements({
      canMonitor: ({ source }) => !this.busy
        && isItemFromRoot(this.element, source.data),
      onDrop: (args) => {
        void this.handleDrop(args);
      },
    });
    this.element.addEventListener('turbo:morph-element', this.scheduleRegistrationHeal);
    // The value callback misses a reconnect of the same controller instance:
    // Stimulus fires it only when the attribute string changes, and a cached
    // root re-attaching still carries the old one. setupSelection is guarded
    // against the overlap.
    if (this.selectionEnabledValue) {
      this.setupSelection();
    }
  }

  disconnect():void {
    this.element.removeEventListener('turbo:morph-element', this.scheduleRegistrationHeal);
    this.teardownSelection();
    this.monitorCleanupFn?.();
    this.monitorCleanupFn = undefined;
    // A drag in flight when the controller disconnects would otherwise leave
    // its marks in the cached page and its frozen batch in this instance.
    this.clearDraggingRows();
    this.activeDragBatch = null;
  }

  // A Turbo morph can toggle the permission-gated value on a live root
  // without reconnecting the controller, so the gestures follow the flip
  // rather than waiting for one.
  selectionEnabledValueChanged():void {
    if (this.selectionEnabledValue) {
      this.setupSelection();
    } else {
      this.teardownSelection();
    }
  }

  // Constructed only for a consumer that opted in, listeners and all: a
  // root that never opted in must not swallow Space or the arrows.
  private setupSelection():void {
    // The callback also fires for a later write of the same value, which
    // must not stack listeners or replace the live model.
    if (this.selection) {
      return;
    }

    this.selection = new SelectionOrchestrator(this);
    // Capture phase: a modified gesture has to be consumed before the
    // card's own navigation listener sees it, whichever connected first.
    this.element.addEventListener('click', this.onSelectionClick, true);
    this.element.addEventListener('keydown', this.onSelectionKeydown, true);
    // At the document, in the bubble phase: clearing must not depend on
    // focus sitting on a card row, and an overlay's Escape runs first.
    document.addEventListener('keydown', this.onSelectionEscape);
    // A restored page brings its markup back but not the model, so batch
    // presentation present at connect time claims a selection nothing
    // holds. Not `turbo:before-cache`: that also fires for the details-pane
    // navigation that morphs this page in place, where the controller never
    // went away and the highlight has to survive.
    this.selection.clearPresentation();
  }

  private teardownSelection():void {
    if (!this.selection) {
      return;
    }

    this.element.removeEventListener('click', this.onSelectionClick, true);
    this.element.removeEventListener('keydown', this.onSelectionKeydown, true);
    document.removeEventListener('keydown', this.onSelectionEscape);
    this.selection.teardown();
    this.selection = undefined;
  }

  private readonly onSelectionClick = (event:MouseEvent):void => {
    this.selection?.handleClick(event);
  };

  private readonly onSelectionKeydown = (event:KeyboardEvent):void => {
    this.selection?.handleKeydown(event);
  };

  private readonly onSelectionEscape = (event:KeyboardEvent):void => {
    this.selection?.handleEscape(event);
  };

  get rootElement():HTMLElement {
    return this.element;
  }

  get announcementScope():string {
    return this.announcementScopeValue;
  }

  get descriptionId():string {
    return this.selectionDescriptionIdValue;
  }

  // Through the item's own outlet, so the consumer decides which element
  // inside the row holds the tab stop.
  focusItem(target:HTMLElement):void {
    const outlet = this.sortableListsItemOutlets.find((item) => item.element === target);

    if (outlet) {
      outlet.focusItem();
    } else {
      target.focus();
    }
  }

  // Live ordered membership, for AGILE-278's batch move.
  selectedItems():SelectionItem[] {
    return this.selection?.selectedItems() ?? [];
  }

  actionScopeFor(itemElement:HTMLElement):ActionScope {
    return this.selection?.actionScopeFor(itemElement) ?? { kind: 'refused', items: [] };
  }

  selectForAction(itemElement:HTMLElement):ActionScope {
    if (this.busy) {
      return this.actionScopeFor(itemElement);
    }

    return this.selection?.selectForAction(itemElement) ?? { kind: 'refused', items: [] };
  }

  // Consumer-owned non-optimistic forms do not call performMove, so their
  // successful move event is the shared boundary at which the live batch is
  // cleared. Failed requests emit no completion event and keep the selection.
  clearSelectionAfterMove():void {
    this.selection?.clearSilently();
  }

  // Where the batch may move: the candidates every member accepts, minus the
  // one they all already occupy, which would be a move to nowhere.
  availableDestinations(scope:ActionScope, candidates:DestinationIdentity[]):DestinationIdentity[] {
    if (scope.kind === 'refused') {
      return [];
    }

    const ownerDestinationOf = (item:HTMLElement) => this.ownerDestinationOf(item);
    const permitted = permittedDestinations({ items: scope.items, candidates, ownerDestinationOf });

    return permitted.filter((target) => (
      !scope.items.every((item) => sameDestination(ownerDestinationOf(item), target))
    ));
  }

  // Frozen at drag start and consumed exactly once per drop, cancelled ones
  // included: neither Escape nor a mid-drag morph can change what is
  // submitted, and no stale batch leaks into the next drag.
  private activeDragBatch:SelectionItem[]|null = null;

  // Pragmatic dispatches onGenerateDragPreview before onDragStart; the
  // preview needs the count, the drag start marks the rows.
  freezeDragBatch(itemElement:HTMLElement):number {
    const scope = this.selection?.selectForAction(itemElement);
    this.activeDragBatch = scope?.kind === 'batch'
      ? scope.items.map((item) => itemIdentity(item)).filter((item):item is SelectionItem => item !== null)
      : null;

    return Math.max(1, this.activeDragBatch?.length ?? 0);
  }

  markDragBatch():void {
    if (this.activeDragBatch) {
      this.markDraggingRows(this.activeDragBatch);
    }
  }

  // The destinations every member of the prospective batch accepts, null when
  // the block reaches all of them. A batch may span lists, so a member that
  // only accepts its own pins the block there, never to the dragged card's
  // list.
  dragPermittedDestinations(itemElement:HTMLElement):DestinationIdentity[]|null {
    const scope = this.selection?.actionScopeFor(itemElement);
    const members = scope?.kind === 'batch' ? scope.items : [itemElement];
    const ownerDestinationOf = (item:HTMLElement) => this.ownerDestinationOf(item);

    const lists = this.ownedListOutlets();
    const permitted = lists
      .map((list) => this.destinationOf(list.listData))
      .filter((destination) => members.every((member) => itemAcceptsDestination(member, destination, ownerDestinationOf)));

    return permitted.length === lists.length ? null : permitted;
  }

  // Asked in canDrag, the earliest point a drag can be stopped: an oversized
  // batch is told so before any preview or drop feedback appears.
  dragRefused(itemElement:HTMLElement):boolean {
    if (this.maxBatchSizeValue <= 0) {
      return false;
    }

    const scope = this.selection?.actionScopeFor(itemElement);
    const count = scope?.kind === 'batch' ? scope.items.length : 1;
    if (count <= this.maxBatchSizeValue) {
      return false;
    }

    void announce(
      I18n.t(`${this.moveAnnouncementScopeValue}.batch_too_large`, { count, max: this.maxBatchSizeValue }),
      { politeness: 'assertive' },
    );
    return true;
  }

  externalDragItems(itemElement:HTMLElement):HTMLElement[] {
    const scope = this.selection?.actionScopeFor(itemElement);
    return scope?.kind === 'batch' ? scope.items : [itemElement];
  }

  private destinationOf(listData:SortableListData):DestinationIdentity {
    return { type: listData.type, id: listData.listId == null ? null : String(listData.listId) };
  }

  // Outlets match document-wide; another root's lists are not ours.
  private ownedListOutlets() {
    return this.sortableListsListOutlets.filter((list) => this.element.contains(list.element));
  }

  // Marked on the item element itself, the same one the item controller's
  // own onDragStart marks, so CSS keys off one convention regardless of
  // which controller did the marking.
  private markDraggingRows(items:SelectionItem[]):void {
    const elements = this.itemElementsByKey();
    items.forEach((item) => {
      elements.get(selectionKey(item))?.setAttribute('data-dragging', 'source');
    });
  }

  // Every mark under the root, not just the frozen batch's own rows: a
  // cancelled drop, or the item controller's onDrop missing a row, would
  // otherwise leave one behind.
  private clearDraggingRows():void {
    this.element.querySelectorAll('[data-dragging]').forEach((element) => element.removeAttribute('data-dragging'));
  }

  // One document query per callback; never kept, so a morph cannot leave it
  // stale. Keyed on type as well as id: ids collide across source tables.
  private itemElementsByKey():Map<SelectionKey, HTMLElement> {
    const map = new Map<SelectionKey, HTMLElement>();
    orderedItemElements(this.element).forEach((element) => {
      const identity = itemIdentity(element);
      if (identity) {
        map.set(selectionKey(identity), element);
      }
    });
    return map;
  }

  private takeActiveDragBatch():SelectionItem[]|null {
    const batch = this.activeDragBatch;
    this.clearDraggingRows();
    this.activeDragBatch = null;
    return batch;
  }

  // A morph desyncs the children's drag-and-drop state in two ways. Stimulus
  // outlet-connected callbacks do not fire reliably for elements a morph
  // replaces, so those children never receive the root reference and refuse
  // every drag and drop (canDrag/canDrop gate on it). And Pragmatic DnD tracks
  // drop targets in both a marker attribute and a WeakMap registration, which
  // a morph can strip or orphan; an element left with the attribute but no
  // registration silently aborts Pragmatic's drop-target search, killing
  // every row rendered underneath it. Re-hand the root and re-register all
  // children once per morph batch — reregistration restores attribute and
  // registration together (which is why the morph attribute preservation
  // deliberately lets the marker be stripped), and the outlet getters query
  // the DOM live, so they see even the children whose connected callbacks
  // were skipped. The microtask runs before any further drag event can
  // observe the desync, so a morph mid-drag stays safe too.
  private scheduleRegistrationHeal = ():void => {
    if (this.healScheduled) {
      return;
    }

    this.healScheduled = true;
    queueMicrotask(() => {
      this.healScheduled = false;
      const children = [
        ...this.sortableListsListOutlets,
        ...this.sortableListsItemOutlets,
        ...this.sortableListsScrollableOutlets,
      ];
      children.forEach((child) => {
        // Outlet selectors are document-scoped, so a broad selector can match
        // another root's children; repair only the ones this root owns.
        if (!this.element.contains(child.element)) {
          return;
        }

        child.connectRoot(this);
        child.reregister();
      });

      // Once per morph batch, not per disconnect: a morph can replace a row
      // with a fresh element for the same work package, and the disconnect
      // alone would drop a member about to come straight back.
      // Re-synced on every morph whether or not prune dropped anything: a
      // morph can strip or preserve the marker attribute independently of
      // the model.
      this.selection?.reconcile();

      // A row a morph replaces mid-drag comes back as fresh server HTML that
      // never went through markDragBatch, so it loses data-dragging with the
      // element it replaced.
      if (this.activeDragBatch) {
        this.markDraggingRows(this.activeDragBatch);
      }
    });
  };

  sortableListsListOutletConnected(list:RootAwareChild):void {
    list.connectRoot(this);
  }

  sortableListsListOutletDisconnected(list:RootAwareChild):void {
    list.disconnectRoot();
  }

  sortableListsItemOutletConnected(item:RootAwareChild):void {
    item.connectRoot(this);
    this.scheduleSelectionReconcile();
  }

  sortableListsItemOutletDisconnected(item:RootAwareChild):void {
    item.disconnectRoot();
    this.scheduleSelectionReconcile();
  }

  // Rows can be replaced without a morph — a frame navigation such as the
  // "show more" expander swaps them wholesale — and the fresh rows carry no
  // marker. Outlet callbacks arrive after the whole mutation batch, so one
  // microtask later the members that survived are present to be repainted
  // and the ones that vanished can be pruned.
  private scheduleSelectionReconcile():void {
    if (this.reconcileScheduled) {
      return;
    }

    this.reconcileScheduled = true;
    queueMicrotask(() => {
      this.reconcileScheduled = false;
      this.selection?.reconcile();
    });
  }

  sortableListsScrollableOutletConnected(scrollable:RootAwareChild):void {
    scrollable.connectRoot(this);
  }

  sortableListsScrollableOutletDisconnected(scrollable:RootAwareChild):void {
    scrollable.disconnectRoot();
  }

  get busy():boolean {
    return this.element.hasAttribute(sortableListsBusyAttribute);
  }

  // A direction is offered exactly when the move resolver can produce a
  // target for it, and never for an item moveInDirection would refuse below.
  // Null means the item is not in an owned list yet. A snapshot for menu
  // gating; the click path re-resolves the live DOM.
  moveAvailability(itemElement:HTMLElement):MoveAvailability|null {
    if (!isOrderableItem(itemElement)) {
      return null;
    }

    const scope = this.actionScopeFor(itemElement);
    if (scope.kind === 'refused') {
      return null;
    }

    if (!this.resolveCollectionMoveUrl()) {
      return { top: false, up: false, down: false, bottom: false };
    }

    const list = this.ownerListOf(itemElement);

    return list
      ? resolveBlockMoveAvailability({ itemElements: scope.items, rowsContainer: list.rowsContainer })
      : null;
  }

  moveToDestination(itemElement:HTMLElement, target:DestinationIdentity):void {
    if (this.busy) {
      return;
    }

    const moveUrl = this.resolveCollectionMoveUrl(false);
    if (!moveUrl) {
      return;
    }

    const scope = this.selectForAction(itemElement);
    if (scope.kind === 'refused') {
      return;
    }

    const body = new FormData();
    scopeIds(scope).forEach((id) => body.append('ids[]', id));
    body.append('list_type', target.type);
    body.append('list_id', target.id ?? '');

    void this.submitDestinationMove(moveUrl, body);
  }

  moveInDirection(itemElement:HTMLElement, direction:MoveDirection):void {
    // The menu is rendered server-side from a permission check that does not
    // know about per-work-package movability, so a stale or over-permissive
    // menu must not execute a move the server will refuse.
    if (this.busy || !isOrderableItem(itemElement)) {
      return;
    }

    if (this.selection) {
      const moveUrl = this.resolveCollectionMoveUrl();
      if (!moveUrl) {
        return;
      }

      // Resolved without mutating: every check below can still refuse the
      // move, and a stale menu must not replace the user's batch with the
      // invoker for a move that then never runs.
      const scope = this.actionScopeFor(itemElement);
      if (scope.kind === 'refused') {
        return;
      }

      const list = this.ownerListOf(itemElement);
      if (!list) {
        return;
      }

      const resolution = resolveBlockMove({
        itemElements: scope.items,
        direction,
        rowsContainer: list.rowsContainer,
      });
      if (!resolution.available) {
        return;
      }

      // Scope members are resolved candidates, so both identity attributes
      // exist; refusing on a mismatch keeps the moved rows and the submitted
      // ids from ever diverging.
      const items = scope.items.flatMap((element):SelectionItem[] => {
        const type = resolveItemType(element);
        const id = resolveItemId(element);
        return type && id ? [{ type, id }] : [];
      });
      if (items.length !== scope.items.length) {
        return;
      }

      // Committed only now the move is known executable: invoking a position
      // action on an unselected card selects it, and a failed request keeps
      // that selection for the retry.
      this.selectForAction(itemElement);

      void this.performMove({
        rows: resolution.rows,
        items,
        rowsContainer: list.rowsContainer,
        listData: list.listData,
        previousItemId: resolution.previousItemId,
        moveUrl,
      });
      return;
    }

    const list = this.ownerListOf(itemElement);
    if (!list) {
      return;
    }

    const itemId = resolveItemId(itemElement);
    if (!itemId) {
      return;
    }

    const previousItemId = resolveDirectionalPreviousItemId({ itemElement, direction, rowsContainer: list.rowsContainer });
    if (previousItemId === undefined) {
      return;
    }

    const moveUrl = this.resolveMoveUrl({ itemId, type: resolveItemType(itemElement) });
    const sourceRow = rowOf(list.rowsContainer, itemElement);
    if (!moveUrl || !sourceRow) {
      return;
    }

    void this.performMove({
      rows: [sourceRow],
      items: null,
      rowsContainer: list.rowsContainer,
      listData: list.listData,
      previousItemId,
      moveUrl,
    });
  }

  // The owning list of an item is the innermost list outlet containing its
  // element: in nested topologies (a section item hosting a field list) the
  // item is contained by every ancestor list, and only the innermost one
  // holds its row.
  private ownerListOf(itemElement:HTMLElement) {
    const containing = this.sortableListsListOutlets.filter((list) => list.element.contains(itemElement));

    return containing.find((list) => !containing.some((other) => other !== list && list.element.contains(other.element))) ?? null;
  }

  ownerListElementOf(itemElement:HTMLElement):HTMLElement|null {
    return this.ownerListOf(itemElement)?.element ?? null;
  }

  ownerRowsContainer(itemElement:HTMLElement):HTMLElement|null {
    return this.ownerListOf(itemElement)?.rowsContainer ?? null;
  }

  ownerDestinationOf(element:HTMLElement):DestinationIdentity|null {
    const listData = this.ownerListOf(element)?.listData;
    return listData ? this.destinationOf(listData) : null;
  }

  private async handleDrop({ location, source }:ElementDropPayload) {
    // Before any bail-out below: a cancelled drop still consumes the frozen
    // snapshot rather than leaking it into the next drag.
    const frozenBatch = this.takeActiveDragBatch();

    if (this.busy) {
      debugLog('sortable-lists: ignoring drop, a move is already in progress');
      return;
    }

    if (!isItemFromRoot(this.element, source.data) || !(source.element instanceof HTMLElement)) {
      debugLog('sortable-lists: ignoring drop, source is not a sortable item', source.data);
      return;
    }

    if (!this.element.contains(source.element)) {
      debugLog('sortable-lists: ignoring drop, source does not belong to this root');
      return;
    }

    const batch = this.batchForDrop(frozenBatch, source.data);
    const moveUrl = batch
      ? this.resolveCollectionMoveUrl()
      : this.resolveMoveUrl({ itemId: source.data.itemId, type: source.data.type });
    if (!moveUrl) {
      debugLog('sortable-lists: ignoring drop, no move URL for item', source.data.itemId);
      return;
    }

    // One item type per batch, so the exclusion set is that type plus ids.
    const intent = resolveDropIntent({
      location,
      root: this.element,
      sourceData: source.data,
      excludedItems: {
        type: source.data.type,
        ids: new Set((batch ?? singleItemBatch(source.data)).map((item) => item.id)),
      },
    });
    if (!intent) {
      debugLog('sortable-lists: ignoring drop, it did not resolve to a move');
      return;
    }

    const rows = batch
      ? this.rowsForItems(batch)
      : this.singleSourceRow(source.element);
    if (!rows) {
      debugLog('sortable-lists: ignoring drop, could not resolve every batch row');
      this.announceMoveFailure({ label: null, listName: null, crossList: false }, false, batch?.length ?? 1);
      return;
    }

    await this.performMove({
      rows,
      items: batch,
      rowsContainer: intent.rowsContainer,
      listData: intent.listData,
      previousItemId: intent.previousItemId,
      moveUrl,
    });
  }

  // A selection-enabled root with a collection URL uses the collection
  // contract for one dragged card as well as many.
  private batchForDrop(frozenBatch:SelectionItem[]|null, sourceData:{ type:string; itemId:string }):SelectionItem[]|null {
    if (!this.collectionMoveUrl || !this.selection) {
      return null;
    }

    return frozenBatch && frozenBatch.length > 0
      ? frozenBatch
      : singleItemBatch(sourceData);
  }

  private get collectionMoveUrl():string|null {
    return this.hasCollectionMoveUrlValue && this.collectionMoveUrlValue !== '' ? this.collectionMoveUrlValue : null;
  }

  private resolveCollectionMoveUrl(optimistic = this.optimisticValue):string|null {
    const collectionMoveUrl = this.collectionMoveUrl;
    if (!collectionMoveUrl) {
      return null;
    }

    const url = new URL(collectionMoveUrl, window.location.href);
    if (optimistic) {
      url.searchParams.set('optimistic', 'true');
    } else {
      url.searchParams.delete('optimistic');
    }

    return relativeUrl(url);
  }

  private async submitDestinationMove(moveUrl:string, body:FormData):Promise<void> {
    const request = new FetchRequest(
      'put',
      moveUrl,
      {
        body,
        responseKind: 'turbo-stream',
      },
    );

    this.startMoveRequest();
    try {
      await performTurboStreamRequest(request);
    } catch (error) {
      // Only a request that never produced a stream lands here — a rejection
      // streams its own flash. Without the toast the busy state would simply
      // clear and the batch would look moved.
      debugLog('Failed to move sortable list items to destination', error);
      this.dispatchErrorToast();
    } finally {
      this.finishMoveRequest();
    }
  }

  // Refused whole when a row is missing: a member that vanished mid-drag
  // means a partial block would diverge from the ids the request claims.
  private rowsForItems(items:SelectionItem[]):HTMLElement[]|null {
    const elements = this.itemElementsByKey();
    const rows:HTMLElement[] = [];

    for (const item of items) {
      const itemElement = elements.get(selectionKey(item)) ?? null;
      const container = itemElement ? this.ownerRowsContainer(itemElement) : null;
      const row = container && itemElement ? rowOf(container, itemElement) : null;
      if (!row) {
        return null;
      }
      rows.push(row);
    }

    return rows;
  }

  private singleSourceRow(sourceElement:HTMLElement):HTMLElement[]|null {
    const sourceList = this.ownerListOf(sourceElement);
    const sourceRow = sourceList ? rowOf(sourceList.rowsContainer, sourceElement) : null;
    return sourceRow ? [sourceRow] : null;
  }

  // Shared by drag drops, single or batch, and by the menu moves that pass
  // no items.
  private async performMove({
    rows,
    items,
    rowsContainer,
    listData,
    previousItemId,
    moveUrl,
  }:{
    rows:HTMLElement[];
    items:SelectionItem[]|null;
    rowsContainer:HTMLElement;
    listData:SortableListData;
    previousItemId:string|null;
    moveUrl:string;
  }):Promise<void> {
    // Captured before the reorder: afterwards the row already belongs to the
    // target list, so source-relative facts would be lost.
    const announcementContext:MoveAnnouncementContext = {
      label: resolveItemLabel(rows[0]),
      listName: listData.name,
      crossList: rows.some((row) => row.parentElement !== rowsContainer),
    };
    const rollback = captureRowPositions(rows);
    reorderRows({ rows, rowsContainer, previousItemId });

    // The reorder resolving back to the block's current DOM position means
    // the move is a no-op — nothing to persist, so no request. Comparing DOM
    // placement (not predecessor ids) keeps non-item rows such as truncation
    // markers out of the equation.
    if (rowsRemainAt(rollback)) {
      debugLog('sortable-lists: ignoring move, the item landed at its original position');
      return;
    }

    this.announceMove(announcementContext, rows, rowsContainer);

    const optimisticPlacement = captureRowPositions(rows);

    const result = await this.moveItem({ listData, previousItemId, moveUrl, items });

    if (result.ok) {
      // Movement clears selection and anchor; failure preserves both for a
      // retry. performMove is the shared boundary for the menu path too.
      this.selection?.clearSilently();
      return;
    }

    let rolledBack = false;
    try {
      // A concurrent morph carries fresher server state than the pre-move
      // snapshot, so roll back only while the rows still sit where the
      // optimistic move put them.
      if (rowsRemainAt(optimisticPlacement)) {
        flipMove(rows, () => restoreRowPositions(rollback));
        // restoreRowPositions silently skips rows whose captured parent
        // disconnected, so the postcondition is verified rather than assumed.
        rolledBack = rowsRemainAt(rollback);
      }
    } catch (error) {
      debugLog('Failed to roll back sortable list item move', error);
    }

    if (result.showToast) {
      this.dispatchErrorToast();
    }
    // A 422 streams its own flash, which knows nothing about the client's
    // rollback: without this, a rejection plus a concurrent morph would leave
    // an unverified rollback unannounced.
    if (result.showToast || !rolledBack) {
      this.announceMoveFailure(announcementContext, rolledBack, rows.length);
    }
  }

  private resolveMoveUrl({ itemId, type }:{ itemId:string; type:string|null }):string|null {
    const template = this.moveUrlTemplateFor(type);
    if (!template) {
      return null;
    }

    const expanded = parseTemplate(template).expand({ id: itemId });
    const url = new URL(expanded, window.location.href);
    // Only consumers whose success response is event-only (Backlogs) opt in;
    // morph-reconciled surfaces need the server to stream the canonical order.
    if (this.optimisticValue) {
      url.searchParams.set('optimistic', 'true');
    }

    return relativeUrl(url);
  }

  // The dragged item's type keys the template: the move endpoint belongs to
  // the item being moved, not to the destination list.
  private moveUrlTemplateFor(type:string|null):string|null {
    if (type !== null && this.hasMoveUrlTemplatesValue && this.moveUrlTemplatesValue[type]) {
      return this.moveUrlTemplatesValue[type];
    }

    return this.hasMoveUrlTemplateValue ? this.moveUrlTemplateValue : null;
  }

  private async moveItem({
    listData,
    previousItemId,
    moveUrl,
    items,
  }:{
    listData:SortableListData;
    previousItemId:string|null;
    moveUrl:string;
    items:SelectionItem[]|null;
  }):Promise<MoveResult> {
    const request = new FetchRequest(
      'put',
      moveUrl,
      {
        // The one boundary where the batch's (type, id) pairs are projected
        // down to the bare ids the PUT takes.
        body: buildMoveFormData({
          listId: listData.listId,
          previousItemId,
          type: listData.type,
          itemIds: items?.map((item) => item.id) ?? null,
        }),
        responseKind: 'turbo-stream',
      },
    );

    this.startMoveRequest();
    try {
      const response = await request.perform();

      if (!response.ok) {
        debugLog(`Failed to move sortable list item: ${response.statusCode}`);
      }

      return response.ok
        ? { ok: true }
        : { ok: false, showToast: response.statusCode !== 422 };
    } catch (error) {
      debugLog('Failed to move sortable list item due to request error', error);
      return { ok: false, showToast: true };
    } finally {
      this.finishMoveRequest();
    }
  }

  private startMoveRequest():void {
    this.inFlightMoveRequests += 1;
    this.syncBusyState();
  }

  private finishMoveRequest():void {
    this.inFlightMoveRequests = Math.max(0, this.inFlightMoveRequests - 1);
    this.syncBusyState();
  }

  private syncBusyState():void {
    // A successful frame stream may already have replaced this root. Avoid
    // mutating detached cached DOM; connect() will project the current count
    // if this element is restored later.
    if (this.element.isConnected) {
      this.setBusy(this.inFlightMoveRequests > 0);
    }
  }

  private setBusy(busy:boolean):void {
    if (busy) {
      this.element.setAttribute(sortableListsBusyAttribute, 'true');
    } else {
      this.element.removeAttribute(sortableListsBusyAttribute);
    }
  }

  private dispatchErrorToast():void {
    window.dispatchEvent(new CustomEvent(OPToastEvent, {
      detail: {
        message: I18n.t('js.error.internal'),
        type: 'error',
      },
    }));
  }

  // The one meaningful message for the whole optimistic move; spoken from the
  // global live region, in sync with what sighted users see. Failure paths
  // append their own message below. A 422 stays silent here: its error flash
  // is streamed by the server and self-announces (matching the toast rule).
  // The consumer's vocabulary: Backlogs says "work package", not "item".
  private announceMove(context:MoveAnnouncementContext, rows:HTMLElement[], rowsContainer:HTMLElement):void {
    const placement = resolveItemPosition({ row: rows[0], rowsContainer });
    if (!placement) {
      return;
    }

    const scope = this.moveAnnouncementScopeValue;
    // Resolved outside the options object literal below: nested inside it,
    // the call's generic return type would be inferred from the object's
    // contextual `TranslateOptions` index signature (`any`) instead of its
    // own `string` default.
    const label = context.label ?? I18n.t(`${scope}.fallback_item_label`);
    const listName = context.listName ?? I18n.t(`${scope}.fallback_list_name`);

    let message:string;
    if (rows.length > 1) {
      const first = placement.position;
      const last = placement.position + rows.length - 1;
      message = context.crossList
        ? I18n.t(`${scope}.moved_batch_to_list`, { count: rows.length, list: listName, first, last, total: placement.total })
        : I18n.t(`${scope}.moved_batch`, { count: rows.length, first, last, total: placement.total });
    } else {
      message = context.crossList
        ? I18n.t(`${scope}.moved_to_list`, { label, list: listName, position: placement.position, total: placement.total })
        : I18n.t(`${scope}.moved`, { label, position: placement.position, total: placement.total });
    }

    void announce(message, { politeness: 'polite' });
  }

  private announceMoveFailure(context:MoveAnnouncementContext, rolledBack:boolean, count:number):void {
    const scope = this.moveAnnouncementScopeValue;
    const label = context.label ?? I18n.t(`${scope}.fallback_item_label`);
    let message:string;
    if (rolledBack) {
      message = count > 1
        ? I18n.t(`${scope}.move_failed_rolled_back_batch`, { count })
        : I18n.t(`${scope}.move_failed_rolled_back`, { label });
    } else {
      message = count > 1
        ? I18n.t(`${scope}.move_failed_check_positions_batch`, { count })
        : I18n.t(`${scope}.move_failed_check_position`);
    }

    void announce(message, { politeness: 'assertive' });
  }

}
