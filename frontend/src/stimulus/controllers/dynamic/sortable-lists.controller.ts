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
  monitorForElements,
  type ElementEventPayloadMap,
} from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { Controller } from '@hotwired/stimulus';
import { FetchRequest } from '@rails/request.js';
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
  restoreRowPositions,
  rowsRemainAt,
  sortableListsBusyAttribute,
} from './sortable-lists/list-dom';

type CleanupFn = () => void;
type ElementDropPayload = ElementEventPayloadMap['onDrop'];
type MoveResult = { ok:true }|{ ok:false; showToast:boolean };

export default class SortableListsController extends Controller<HTMLElement> implements SortableListsRoot {
  static outlets = ['sortable-lists--list', 'sortable-lists--item', 'sortable-lists--scrollable'];

  static values = {
    moveUrlTemplate: String,
  };

  declare readonly sortableListsListOutlets:import('./sortable-lists/list.controller').default[];
  declare readonly sortableListsItemOutlets:RootAwareChild[];
  declare readonly sortableListsScrollableOutlets:RootAwareChild[];

  declare readonly moveUrlTemplateValue:string;
  declare readonly hasMoveUrlTemplateValue:boolean;

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
  // drop targets in both a marker attribute (which the morph attribute
  // preservation keeps alive) and a WeakMap registration (which nothing
  // preserves); an element left with the attribute but no registration
  // silently aborts Pragmatic's drop-target search, killing every row
  // rendered underneath it. Re-hand the root and re-register all children
  // once per morph batch — the outlet getters query the DOM live, so they see
  // even the children whose connected callbacks were skipped. The microtask
  // runs before any further drag event can observe the desync, so a morph
  // mid-drag stays safe too.
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

    const moveUrl = this.resolveMoveUrl(source.data);
    if (!moveUrl) {
      debugLog('sortable-lists: ignoring drop, no move URL for item', source.data.itemId);
      return;
    }

    const intent = resolveDropIntent({
      location,
      root: this.element,
      sourceElement: source.element,
      sourceData: source.data,
    });
    if (!intent) {
      debugLog('sortable-lists: ignoring drop, it did not resolve to a move '
        + '(dropped outside a list or back onto its original position)');
      return;
    }

    // The dragged source row is still resolved as an <li>, the one place the
    // subsystem is not yet tag-agnostic: reaching its rows container structurally
    // needs the source list (not the root) on the item payload. Backlogs rows are
    // <li>, so this holds today; generalising it is a tracked follow-up.
    const sourceRow = source.element.closest('li');
    if (!(sourceRow instanceof HTMLElement)) {
      debugLog('sortable-lists: ignoring drop, could not resolve the source row element');
      return;
    }

    // Move the row optimistically, then persist. The server response (a
    // turbo-stream) reconciles the list on success; a failure rolls the row
    // back to where it started.
    const rows = [sourceRow];
    const rollback = captureRowPositions(rows);
    reorderRows({ rows, rowsContainer: intent.rowsContainer, previousItemId: intent.previousItemId });
    const optimisticPlacement = captureRowPositions(rows);

    const result = await this.moveItem({
      listData: intent.listData,
      previousItemId: intent.previousItemId,
      moveUrl,
    });

    if (!result.ok) {
      try {
        // A concurrent morph that removed or repositioned the rows carries
        // fresher server state than the pre-move snapshot; roll back only
        // while the rows still sit where the optimistic move put them.
        if (rowsRemainAt(optimisticPlacement)) {
          flipMove(rows, () => restoreRowPositions(rollback));
        }
      } catch (error) {
        debugLog('Failed to roll back sortable list item move', error);
      }

      if (result.showToast) {
        this.dispatchErrorToast();
      }
    }
  }

  private resolveMoveUrl(data:{ itemId:string }):string|null {
    if (!this.hasMoveUrlTemplateValue) {
      return null;
    }

    return parseTemplate(this.moveUrlTemplateValue).expand({ id: data.itemId });
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
    this.sortableListsListOutlets.forEach((list) => list.reflectBusy(busy));
  }

  private dispatchErrorToast():void {
    window.dispatchEvent(new CustomEvent(OPToastEvent, {
      detail: {
        message: I18n.t('js.error.internal'),
        type: 'error',
      },
    }));
  }
}
