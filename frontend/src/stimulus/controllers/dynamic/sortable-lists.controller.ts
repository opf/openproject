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
import { extractClosestEdge } from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';
import {
  dropTargetForElements,
  monitorForElements,
  type ElementEventPayloadMap,
} from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { Controller } from '@hotwired/stimulus';
import { FetchRequest } from '@rails/request.js';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { withLoadingIndicator } from 'core-stimulus/helpers/request-helpers';
import URI from 'urijs';
import 'urijs/src/URITemplate';
import {
  acceptsSortableItemType,
  buildMoveFormData,
  isSortableItemData,
  isSourceListTarget,
  resolveFallbackDropTarget,
  resolveListAppendPreviousItemId,
  resolveListData,
  resolvePreviousSortableItemId,
  sortableItemSelector,
  sortableListsMovingAttribute,
  type SortableItemData,
  type SortableListData,
} from './sortable-lists/drag-and-drop';

type CleanupFn = () => void;
type ElementDropPayload = ElementEventPayloadMap['onDrop'];
type AutoScrollAllowedAxis = 'vertical'|'horizontal'|'all';
type AutoScrollMaxScrollSpeed = 'standard'|'fast';

const allowedAxes = new Set<string>(['vertical', 'horizontal', 'all']);
const maxScrollSpeeds = new Set<string>(['standard', 'fast']);

export default class SortableListsController extends Controller<HTMLElement> {
  static targets = ['list', 'scrollable'];

  static values = {
    acceptedType: String,
    moveUrlTemplate: String,
    allowedAxis: { type: String, default: 'vertical' },
    maxScrollSpeed: { type: String, default: 'standard' },
  };

  declare readonly listTargets:HTMLElement[];
  declare readonly scrollableTargets:HTMLElement[];

  declare readonly acceptedTypeValue:string;
  declare readonly hasAcceptedTypeValue:boolean;
  declare readonly moveUrlTemplateValue:string;
  declare readonly hasMoveUrlTemplateValue:boolean;
  declare readonly allowedAxisValue:string;
  declare readonly maxScrollSpeedValue:string;

  private monitorCleanupFn?:CleanupFn;
  private listCleanupFns = new Map<HTMLElement, CleanupFn>();
  private scrollableCleanupFns = new Map<HTMLElement, CleanupFn>();
  private readonly handleMorphBound = this.handleMorph.bind(this);

  connect():void {
    this.monitorCleanupFn = monitorForElements({
      canMonitor: ({ source }) => !this.moving && isSortableItemData(source.data),
      onDrop: (args) => {
        void this.handleDrop(args);
      },
    });
    document.addEventListener('turbo:morph-element', this.handleMorphBound);
  }

  disconnect():void {
    this.monitorCleanupFn?.();
    this.monitorCleanupFn = undefined;
    document.removeEventListener('turbo:morph-element', this.handleMorphBound);
    this.listCleanupFns.forEach((cleanup) => cleanup());
    this.listCleanupFns.clear();
    this.scrollableCleanupFns.forEach((cleanup) => cleanup());
    this.scrollableCleanupFns.clear();
  }

  listTargetConnected(element:HTMLElement):void {
    const cleanup = dropTargetForElements({
      element,
      canDrop: ({ source }) => !this.moving && isSortableItemData(source.data) && acceptsSortableItemType({
        acceptedType: this.acceptedType,
        type: source.data.type,
      }),
      getData: () => resolveListData(element) ?? {},
      getIsSticky: () => false,
    });

    this.listCleanupFns.set(element, cleanup);
  }

  listTargetDisconnected(element:HTMLElement):void {
    this.listCleanupFns.get(element)?.();
    this.listCleanupFns.delete(element);
  }

  scrollableTargetConnected(element:HTMLElement):void {
    const cleanup = autoScrollForElements({
      element,
      canScroll: ({ source }) => isSortableItemData(source.data),
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

  private get acceptedType():string|null {
    // The accepted type is scoped to this controller instance, so every list target
    // inside one sortable-lists root accepts the same sortable item type.
    return this.hasAcceptedTypeValue ? this.acceptedTypeValue : null;
  }

  private get maxScrollSpeed():AutoScrollMaxScrollSpeed {
    return maxScrollSpeeds.has(this.maxScrollSpeedValue) ? this.maxScrollSpeedValue as AutoScrollMaxScrollSpeed : 'standard';
  }

  private get moving():boolean {
    return this.element.hasAttribute(sortableListsMovingAttribute);
  }

  private async handleDrop({ location, source }:ElementDropPayload) {
    if (this.moving) {
      return;
    }

    if (!isSortableItemData(source.data) || !(source.element instanceof HTMLElement)) {
      return;
    }

    if (
      !this.element.contains(source.element) ||
      !acceptsSortableItemType({
        acceptedType: this.acceptedType,
        type: source.data.type,
      })
    ) {
      return;
    }

    const moveUrl = this.resolveMoveUrl(source.data);
    if (!moveUrl) {
      return;
    }

    const targetItem = location.current.dropTargets.find(({ data, element }) => (
      isSortableItemData(data) && element instanceof HTMLElement && this.element.contains(element)
    ));
    const targetList = location.current.dropTargets.find(({ element }) => (
      element instanceof HTMLElement && this.element.contains(element)
    ));
    const fallbackTarget = location.current.dropTargets.length === 0
      ? resolveFallbackDropTarget({
        input: location.current.input,
        root: this.element,
        sourceElement: source.element,
      })
      : null;
    const fallbackItem = fallbackTarget?.isItem ? fallbackTarget : null;
    const resolvedTargetItem = targetItem ?? fallbackItem;
    const targetElement = resolvedTargetItem?.element ?? targetList?.element ?? fallbackTarget?.element;

    if (!(targetElement instanceof HTMLElement)) {
      return;
    }

    const listData = resolveListData(targetElement);
    if (!listData) {
      return;
    }

    if (!resolvedTargetItem && isSourceListTarget({ sourceElement: source.element, targetElement })) {
      return;
    }

    const previousItemId = resolvedTargetItem?.element instanceof HTMLElement
      ? resolvePreviousSortableItemId({
        sourceItemId: source.data.itemId,
        targetItem: resolvedTargetItem.element,
        closestEdge: extractClosestEdge(resolvedTargetItem.data),
      })
      : resolveListAppendPreviousItemId({
        sourceItemId: source.data.itemId,
        list: targetElement,
      });

    await this.moveItem({
      listData,
      previousItemId,
      sourceData: source.data,
    });
  }

  // A Turbo morph can strip the Pragmatic DnD attributes/listeners an item
  // controller applied to its row. One root-level listener refreshes the
  // affected item, instead of every item registering its own document listener.
  private handleMorph(event:Event):void {
    const target = event.target;

    if (!(target instanceof HTMLElement) || !target.matches(sortableItemSelector) || !this.element.contains(target)) {
      return;
    }

    const controller = this.application.getControllerForElementAndIdentifier(target, 'sortable-lists--item');
    (controller as { refresh?:() => void }|null)?.refresh?.();
  }

  private async moveItem({
    listData,
    previousItemId,
    sourceData,
  }:{
    listData:SortableListData;
    previousItemId:string|null;
    sourceData:SortableItemData;
  }):Promise<void> {
    const moveUrl = this.resolveMoveUrl(sourceData);
    if (!moveUrl) {
      return;
    }

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

    this.setMoving(true);
    try {
      const response = await withLoadingIndicator(request.perform());

      if (!response.ok) {
        debugLog(`Failed to move sortable list item: ${response.statusCode}`);
      }
    } catch (error) {
      debugLog('Failed to move sortable list item due to request error', error);
      this.dispatchErrorToast();
    } finally {
      this.setMoving(false);
    }
  }

  private setMoving(moving:boolean):void {
    if (moving) {
      this.element.setAttribute(sortableListsMovingAttribute, 'true');
      this.element.setAttribute('aria-busy', 'true');
    } else {
      this.element.removeAttribute(sortableListsMovingAttribute);
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

  private resolveMoveUrl(data:{ itemId:string; moveUrl?:string }):string|null {
    if (data.moveUrl) {
      return data.moveUrl;
    }

    if (this.hasMoveUrlTemplateValue) {
      return URI.expand?.(this.moveUrlTemplateValue, { id: data.itemId }).toString() ?? null;
    }

    return null;
  }
}
