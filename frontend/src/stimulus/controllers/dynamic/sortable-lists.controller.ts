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
import { parseTemplate } from 'url-template';
import {
  buildMoveFormData,
  isSortableItemData,
  resolveDropIntent,
  type RootAwareChild,
  type SortableListData,
  type SortableListsRoot,
} from './sortable-lists/drag-and-drop';
import {
  captureRowPositions,
  reorderRows,
  resolveDirectionalPreviousItemId,
  resolveItemId,
  resolveItemLabel,
  resolveItemPosition,
  resolveItemType,
  resolveMoveAvailability,
  restoreRowPositions,
  rowOf,
  rowsRemainAt,
  sortableListsBusyAttribute,
  type MoveAvailability,
  type MoveDirection,
} from './sortable-lists/list-dom';

type CleanupFn = () => void;
type ElementDropPayload = ElementEventPayloadMap['onDrop'];
type MoveResult = { ok:true }|{ ok:false; showToast:boolean };
interface MoveAnnouncementContext { label:string|null; listName:string|null; crossList:boolean }

export default class SortableListsController extends Controller<HTMLElement> implements SortableListsRoot {
  static outlets = ['sortable-lists--list', 'sortable-lists--item', 'sortable-lists--scrollable'];

  static values = {
    moveUrlTemplate: String,
    moveUrlTemplates: Object,
    optimistic: { type: Boolean, default: false },
  };

  declare readonly sortableListsListOutlets:import('./sortable-lists/list.controller').default[];
  declare readonly sortableListsItemOutlets:RootAwareChild[];
  declare readonly sortableListsScrollableOutlets:RootAwareChild[];

  declare readonly moveUrlTemplateValue:string;
  declare readonly hasMoveUrlTemplateValue:boolean;
  declare readonly moveUrlTemplatesValue:Record<string, string>;
  declare readonly hasMoveUrlTemplatesValue:boolean;
  declare readonly optimisticValue:boolean;

  private monitorCleanupFn?:CleanupFn;
  private healScheduled = false;

  connect():void {
    this.monitorCleanupFn = monitorForElements({
      canMonitor: ({ source }) => !this.busy
        && isSortableItemData(source.data)
        && source.data.rootElement === this.element,
      onDrop: (args) => {
        void this.handleDrop(args);
      },
    });
    this.element.addEventListener('turbo:morph-element', this.scheduleRegistrationHeal);
  }

  disconnect():void {
    this.element.removeEventListener('turbo:morph-element', this.scheduleRegistrationHeal);
    this.monitorCleanupFn?.();
    this.monitorCleanupFn = undefined;
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
  }

  sortableListsItemOutletDisconnected(item:RootAwareChild):void {
    item.disconnectRoot();
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

  // Availability mirrors executability: a direction is offered exactly when the
  // move resolver can produce a target for it. This keeps the menu honest about
  // truncated lists, where a one-step move across the hidden block is not
  // addressable. Null means the item is not in an owned list (yet). The result
  // is a snapshot for menu gating; the click path re-resolves the live DOM.
  moveAvailability(itemElement:HTMLElement):MoveAvailability|null {
    const list = this.ownerListOf(itemElement);

    return list ? resolveMoveAvailability({ itemElement, rowsContainer: list.rowsContainer }) : null;
  }

  moveInDirection(itemElement:HTMLElement, direction:MoveDirection):void {
    if (this.busy) {
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
      sourceRow,
      rowsContainer: list.rowsContainer,
      listData: list.listData,
      previousItemId,
      moveUrl,
    });
  }

  // The list element an item currently belongs to, for the confinement field
  // on the drag payload; null outside any registered list.
  ownerListElementOf(itemElement:HTMLElement):HTMLElement|null {
    return this.ownerListOf(itemElement)?.element ?? null;
  }

  // The owning list of an item is the innermost list outlet containing its
  // element: in nested topologies (a section item hosting a field list) the
  // item is contained by every ancestor list, and only the innermost one
  // holds its row.
  private ownerListOf(itemElement:HTMLElement) {
    const containing = this.sortableListsListOutlets.filter((list) => list.element.contains(itemElement));

    return containing.find((list) => !containing.some((other) => other !== list && list.element.contains(other.element))) ?? null;
  }

  ownerRowsContainer(itemElement:HTMLElement):HTMLElement|null {
    return this.ownerListOf(itemElement)?.rowsContainer ?? null;
  }

  private async handleDrop({ location, source }:ElementDropPayload) {
    if (this.busy) {
      debugLog('sortable-lists: ignoring drop, a move is already in progress');
      return;
    }

    if (!isSortableItemData(source.data) || !(source.element instanceof HTMLElement)) {
      debugLog('sortable-lists: ignoring drop, source is not a sortable item', source.data);
      return;
    }

    if (!this.element.contains(source.element)) {
      debugLog('sortable-lists: ignoring drop, source does not belong to this root');
      return;
    }

    const moveUrl = this.resolveMoveUrl({ itemId: source.data.itemId, type: source.data.type });
    if (!moveUrl) {
      debugLog('sortable-lists: ignoring drop, no move URL for item', source.data.itemId);
      return;
    }

    const intent = resolveDropIntent({
      location,
      root: this.element,
      sourceData: source.data,
    });
    if (!intent) {
      debugLog('sortable-lists: ignoring drop, it did not resolve to a move');
      return;
    }

    const sourceList = this.ownerListOf(source.element);
    const sourceRow = sourceList ? rowOf(sourceList.rowsContainer, source.element) : null;
    if (!sourceRow) {
      debugLog('sortable-lists: ignoring drop, could not resolve the source row element');
      return;
    }

    await this.performMove({
      sourceRow,
      rowsContainer: intent.rowsContainer,
      listData: intent.listData,
      previousItemId: intent.previousItemId,
      moveUrl,
    });
  }

  // Optimistically reorder a single row, persist the move, and roll the row
  // back (with a FLIP animation and an error toast) if the server rejects it.
  // Shared by drag drops and programmatic menu moves.
  private async performMove({
    sourceRow,
    rowsContainer,
    listData,
    previousItemId,
    moveUrl,
  }:{
    sourceRow:HTMLElement;
    rowsContainer:HTMLElement;
    listData:SortableListData;
    previousItemId:string|null;
    moveUrl:string;
  }):Promise<void> {
    const rows = [sourceRow];
    // Captured before the reorder: afterwards the row already belongs to the
    // target list, so source-relative facts would be lost.
    const announcementContext:MoveAnnouncementContext = {
      label: resolveItemLabel(sourceRow),
      listName: listData.name,
      crossList: sourceRow.parentElement !== rowsContainer,
    };
    const rollback = captureRowPositions(rows);
    reorderRows({ rows, rowsContainer, previousItemId });

    // The reorder resolving back to the source's current DOM position means
    // the move is a no-op — nothing to persist, so no request. Comparing DOM
    // placement (not predecessor ids) keeps non-item rows such as truncation
    // markers out of the equation.
    if (rowsRemainAt(rollback)) {
      debugLog('sortable-lists: ignoring move, the item landed at its original position');
      return;
    }

    this.announceMove(announcementContext, sourceRow, rowsContainer);

    const optimisticPlacement = captureRowPositions(rows);

    const result = await this.moveItem({ listData, previousItemId, moveUrl });

    if (!result.ok) {
      let rolledBack = false;
      try {
        // A concurrent morph that removed or repositioned the rows carries
        // fresher server state than the pre-move snapshot; roll back only
        // while the rows still sit where the optimistic move put them.
        if (rowsRemainAt(optimisticPlacement)) {
          flipMove(rows, () => restoreRowPositions(rollback));
          // restoreRowPositions silently skips rows whose captured parent
          // disconnected, so verify the postcondition instead of trusting
          // the absence of an exception.
          rolledBack = rowsRemainAt(rollback);
        }
      } catch (error) {
        debugLog('Failed to roll back sortable list item move', error);
      }

      if (result.showToast) {
        this.dispatchErrorToast();
        this.announceMoveFailure(announcementContext, rolledBack);
      }
    }
  }

  // The template must expand to a same-origin relative URL: the expansion is
  // reduced to path + search + hash, so an absolute template's origin would
  // be dropped silently.
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

    return `${url.pathname}${url.search}${url.hash}`;
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
  }:{
    listData:SortableListData;
    previousItemId:string|null;
    moveUrl:string;
  }):Promise<MoveResult> {
    const request = new FetchRequest(
      'put',
      moveUrl,
      {
        body: buildMoveFormData({
          listId: listData.listId,
          previousItemId,
          type: listData.type,
        }),
        responseKind: 'turbo-stream',
      },
    );

    this.setBusy(true);
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
      this.setBusy(false);
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
  private announceMove(context:MoveAnnouncementContext, sourceRow:HTMLElement, rowsContainer:HTMLElement):void {
    const placement = resolveItemPosition({ row: sourceRow, rowsContainer });
    if (!placement) {
      return;
    }

    // Resolved outside the options object literal below: nested inside it,
    // the call's generic return type would be inferred from the object's
    // contextual `TranslateOptions` index signature (`any`) instead of its
    // own `string` default.
    const label = context.label ?? I18n.t('js.sortable_lists.announcements.fallback_item_label');
    const listName = context.listName ?? I18n.t('js.sortable_lists.announcements.fallback_list_name');
    const message = context.crossList
      ? I18n.t('js.sortable_lists.announcements.moved_to_list', {
        label,
        list: listName,
        position: placement.position,
        total: placement.total,
      })
      : I18n.t('js.sortable_lists.announcements.moved', {
        label,
        position: placement.position,
        total: placement.total,
      });

    void announce(message, { politeness: 'polite' });
  }

  private announceMoveFailure(context:MoveAnnouncementContext, rolledBack:boolean):void {
    const label = context.label ?? I18n.t('js.sortable_lists.announcements.fallback_item_label');
    const message = rolledBack
      ? I18n.t('js.sortable_lists.announcements.move_failed_rolled_back', { label })
      : I18n.t('js.sortable_lists.announcements.move_failed_check_position');

    void announce(message, { politeness: 'assertive' });
  }
}
