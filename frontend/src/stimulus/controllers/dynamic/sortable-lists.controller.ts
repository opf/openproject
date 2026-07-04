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

import { autoScrollForElements } from '@atlaskit/pragmatic-drag-and-drop-auto-scroll/element';
import {
  monitorForElements,
  type ElementEventPayloadMap,
} from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { Controller } from '@hotwired/stimulus';
import { FetchRequest } from '@rails/request.js';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { flipMove } from 'core-stimulus/helpers/flip-helper';
import { parseTemplate } from 'url-template';
import {
  buildMoveFormData,
  isSortableItemData,
  resolveDropIntent,
  type DropIntent,
  type SortableItemData,
  type SortablePositionMode,
} from './sortable-lists/drag-and-drop';
import {
  captureRowPositions,
  hasTruncationMarkerRow,
  reorderRows,
  resolveSourceRow,
  restoreRowPositions,
} from './sortable-lists/list-dom';

type CleanupFn = () => void;
type ElementDropPayload = ElementEventPayloadMap['onDrop'];
type AutoScrollAllowedAxis = 'vertical'|'horizontal'|'all';
type AutoScrollMaxScrollSpeed = 'standard'|'fast';
type MoveResult = { ok:true }|{ ok:false; showToast:boolean };

const allowedAxes = new Set<string>(['vertical', 'horizontal', 'all']);
const maxScrollSpeeds = new Set<string>(['standard', 'fast']);

export default class SortableListsController extends Controller<HTMLElement> {
  static targets = ['scrollable'];

  static values = {
    moveUrlTemplates: { type: Object, default: {} },
    positionMode: { type: String, default: 'relative' },
    allowedAxis: { type: String, default: 'vertical' },
    maxScrollSpeed: { type: String, default: 'standard' },
  };

  declare readonly scrollableTargets:HTMLElement[];

  declare readonly moveUrlTemplatesValue:Record<string, string>;
  declare readonly positionModeValue:string;
  declare readonly allowedAxisValue:string;
  declare readonly maxScrollSpeedValue:string;

  private monitorCleanupFn?:CleanupFn;
  private scrollableCleanupFns = new Map<HTMLElement, CleanupFn>();
  private movingFlag = false;

  get moving():boolean {
    return this.movingFlag;
  }

  connect():void {
    this.monitorCleanupFn = monitorForElements({
      canMonitor: ({ source }) => isSortableItemData(source.data) && source.data.rootElement === this.element,
      onDrop: (args) => {
        void this.handleDrop(args);
      },
    });
  }

  disconnect():void {
    this.monitorCleanupFn?.();
    this.monitorCleanupFn = undefined;
    this.scrollableCleanupFns.forEach((cleanup) => cleanup());
    this.scrollableCleanupFns.clear();
  }

  scrollableTargetConnected(element:HTMLElement):void {
    const cleanup = autoScrollForElements({
      element,
      canScroll: ({ source }) => isSortableItemData(source.data) && source.data.rootElement === this.element,
      getAllowedAxis: () => this.allowedAxis,
      getConfiguration: () => ({ maxScrollSpeed: this.maxScrollSpeed }),
    });

    this.scrollableCleanupFns.set(element, cleanup);
  }

  scrollableTargetDisconnected(element:HTMLElement):void {
    this.scrollableCleanupFns.get(element)?.();
    this.scrollableCleanupFns.delete(element);
  }

  private get allowedAxis():AutoScrollAllowedAxis {
    return allowedAxes.has(this.allowedAxisValue) ? this.allowedAxisValue as AutoScrollAllowedAxis : 'vertical';
  }

  private get maxScrollSpeed():AutoScrollMaxScrollSpeed {
    return maxScrollSpeeds.has(this.maxScrollSpeedValue) ? this.maxScrollSpeedValue as AutoScrollMaxScrollSpeed : 'standard';
  }

  private async handleDrop({ location, source }:ElementDropPayload) {
    if (!isSortableItemData(source.data) || !(source.element instanceof HTMLElement)) {
      return;
    }

    const moveUrl = this.resolveMoveUrl(source.data);
    if (!moveUrl) {
      return;
    }

    const intent = resolveDropIntent({
      location,
      root: this.element,
      sourceElement: source.element,
      sourceData: source.data,
    });
    if (!intent) {
      return;
    }

    const sourceRow = resolveSourceRow(source.element);
    if (!sourceRow) {
      return;
    }

    // Move the row optimistically, then persist. A same-list move into a
    // non-truncated list is answered with 204 and this DOM order is final; a
    // cross-list move, or a same-list move into a truncated list (whose
    // visible window is server-computed), gets a turbo-stream frame reload
    // that reconciles the list. A failure rolls the row back to where it
    // started.
    const rows = [sourceRow];
    const rollback = captureRowPositions(rows);
    reorderRows({ rows, container: intent.rowsContainer, previousItemId: intent.previousItemId });

    const optimistic = !hasTruncationMarkerRow(intent.rowsContainer);
    const result = await this.moveItem({ intent, moveUrl, optimistic });

    if (result.ok) {
      // After moveItem's finally: moving is false again, so listeners resumed
      // by this event (split-view sync, feature-spec waits) observe a root
      // that accepts the next drag.
      this.dispatch('moved', { detail: { itemId: source.data.itemId } });
      return;
    }

    try {
      flipMove(rows, () => restoreRowPositions(rollback));
    } catch (error) {
      debugLog('Failed to roll back sortable list item move', error);
    }

    if (result.showToast) {
      this.dispatchErrorToast();
    }
  }

  private resolveMoveUrl(data:SortableItemData):string|null {
    const template = this.moveUrlTemplatesValue[data.type];
    if (!template) {
      return null;
    }

    return this.withCurrentFrameQuery(parseTemplate(template).expand({ id: data.itemId }));
  }

  private get positionMode():SortablePositionMode {
    return this.positionModeValue === 'absolute' ? 'absolute' : 'relative';
  }

  private withCurrentFrameQuery(moveUrl:string):string {
    const src = this.element.tagName === 'TURBO-FRAME' ? this.element.getAttribute('src') : null;

    if (!src) {
      return moveUrl;
    }

    const frameParams = new URL(src, window.location.href).searchParams;
    if (frameParams.size === 0) {
      return moveUrl;
    }

    const url = new URL(moveUrl, window.location.href);
    const replacedKeys = new Set(frameParams.keys());

    replacedKeys.forEach((key) => url.searchParams.delete(key));
    frameParams.forEach((value, key) => url.searchParams.append(key, value));

    return /^[a-z][a-z\d+\-.]*:/i.test(moveUrl) ? url.toString() : `${url.pathname}${url.search}${url.hash}`;
  }

  private async moveItem({
    intent,
    moveUrl,
    optimistic,
  }:{
    intent:DropIntent;
    moveUrl:string;
    optimistic:boolean;
  }):Promise<MoveResult> {
    const request = new FetchRequest('put', moveUrl, {
      body: buildMoveFormData({ intent, positionMode: this.positionMode, optimistic }),
      responseKind: 'turbo-stream',
    });

    this.setMoving(true);
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
      this.setMoving(false);
    }
  }

  // aria-busy on the root covers all its lists; per-list precision was not
  // needed (review consensus), which lets the root avoid tracking children.
  private setMoving(moving:boolean):void {
    this.movingFlag = moving;
    if (moving) {
      this.element.setAttribute('aria-busy', 'true');
    } else {
      this.element.removeAttribute('aria-busy');
    }
  }

  private dispatchErrorToast():void {
    window.dispatchEvent(new CustomEvent('op:toasters:add', {
      detail: {
        message: I18n.t('js.error.internal'),
        type: 'error',
      },
    }));
  }
}
