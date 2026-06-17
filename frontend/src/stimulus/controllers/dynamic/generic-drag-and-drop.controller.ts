/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';
import { FetchRequest } from '@rails/request.js';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { closestInteractiveElement } from 'core-stimulus/helpers/interactive-element-helper';
import type { DomAutoscrollService } from 'core-app/shared/helpers/drag-and-drop/dom-autoscroll.service';
import type { OpenProjectPluginContext } from 'core-app/features/plugins/plugin-context';
import { useAngularServices } from 'core-stimulus/mixins/use-angular-services';
import dragula, { Drake } from 'dragula';
import invariant from 'tiny-invariant';

interface TargetConfig {
  container:Element;
  allowedDragType:string|null;
  targetId:string|null;
}

export default class GenericDragAndDropController extends Controller {
  static targets = ['container', 'scrollContainer'];

  containerTargets:HTMLElement[];
  scrollContainerTargets:HTMLElement[];

  static values = {
    handle: { type: Boolean, default: true },
    handleSelector: { type: String, default: '.DragHandle' },
    positionMode: { type: String, default: 'index' },
  };

  declare readonly handleValue:boolean;
  declare readonly handleSelectorValue:string;
  declare readonly positionModeValue:string;

  declare pluginContext:Promise<OpenProjectPluginContext>;

  private drake:Drake|null = null;
  private autoscroll:DomAutoscrollService|null = null;
  private containers:HTMLElement[] = [];
  private targetConfigs:TargetConfig[] = [];
  private dragOriginSource:Element|null = null;
  private dragOriginNextSibling:Element|null = null;

  initialize() {
    useAngularServices(this);
  }

  connect() {
    this.autoscroll?.destroy();
    this.drake?.destroy();
    this.initDrake();
  }

  disconnect() {
    // A Turbo morph mid-drag can replace the element tree without the
    // dragend event firing, so clear the body-level cursor flag defensively.
    document.body.removeAttribute('data-dragging');
    this.autoscroll?.destroy();
    this.autoscroll = null;
    this.drake?.destroy();
    this.drake = null;
  }

  containerTargetConnected(target:HTMLElement) {
    const container = this.resolveContainerElement(target);
    const targetConfig:TargetConfig = {
      container,
      allowedDragType: target.getAttribute('data-target-allowed-drag-type'),
      targetId: target.getAttribute('data-target-id'),
    };

    // we need to save the targetConfigs separately as we need to pass the pure container elements to drake
    // but need the configuration of the targets when dropping elements
    this.targetConfigs.push(targetConfig);
    this.containers.push(container);
  }

  containerTargetDisconnected(target:HTMLElement) {
    const container = this.resolveContainerElement(target);
    const index = this.containers.indexOf(container);
    if (index !== -1) {
      this.containers.splice(index, 1);
      this.targetConfigs.splice(index, 1);
    }
  }

  cancelDrag() {
    this.drake?.cancel(true);
  }

  private revertDrop(el:Element) {
    if (this.dragOriginSource) {
      if (this.dragOriginNextSibling?.parentNode === this.dragOriginSource) {
        this.dragOriginSource.insertBefore(el, this.dragOriginNextSibling);
      } else {
        this.dragOriginSource.appendChild(el);
      }
    }
  }

  initDrake() {
    // Note: dragula stores a reference to this.containers, so mutations
    // from containerTargetConnected/Disconnected automatically propagate
    this.drake = dragula(
      this.containers,
      {
        moves: (el, _source, handle, _sibling) => this.canStartDrag(el, handle),
        accepts: (el:Element, target:Element, source:Element, sibling:Element) => this.accepts(el, target, source, sibling),
        revertOnSpill: true, // enable reverting of elements if they are dropped outside of a valid target
      },
    )
      .on('cloned', (clone, _original, type) => {
        clone.setAttribute('data-dragging', type);
      })
      .on('drag', (el, source) => {
        this.dragOriginSource = source;
        this.dragOriginNextSibling = el.nextElementSibling;

        el.setAttribute('data-dragging', 'source');
        document.body.setAttribute('data-dragging', 'active');
        this.ariaPressedTarget(el)?.setAttribute('aria-pressed', 'true');
      })
      .on('dragend', (el) => {
        el.removeAttribute('data-dragging');
        document.body.removeAttribute('data-dragging');
        this.ariaPressedTarget(el)?.setAttribute('aria-pressed', 'false');
      })
      // eslint-disable-next-line @typescript-eslint/no-misused-promises
      .on('drop', this.drop.bind(this));

    void this.setupAutoscroll();
  }

  private async setupAutoscroll() {
    const { classes } = await this.pluginContext;

    const scrollTargets:Element[] = this.scrollContainerTargets.length > 0
      ? this.scrollContainerTargets
      : [document.getElementById('content-body')!];

    this.autoscroll = new classes.DomAutoscrollService(
      scrollTargets,
      {
        margin: 25,
        maxSpeed: 10,
        scrollWhenOutside: true,
        autoScroll: () => this.drake?.dragging,
      },
    );
  }

  accepts(el:Element, target:Element, _source:Element|null, _sibling:Element|null) {
    const targetConfig = this.targetConfigs.find((config) => config.container === target);
    const acceptedDragType = targetConfig?.allowedDragType as string|undefined;

    const draggableType = el.getAttribute('data-draggable-type');

    if (draggableType !== acceptedDragType) {
      debugLog('Element is not allowed to be dropped here');
      return false;
    }

    return true;
  }

  async drop(el:Element, target:Element, _source:Element|null, _sibling:Element|null) {
    const dropUrl = el.getAttribute('data-drop-url');
    const data = this.buildData(el, target);

    if (!dropUrl) {
      return;
    }

    try {
      const request = new FetchRequest('put', dropUrl, { body: data, responseKind: 'turbo-stream' });
      const response = await request.perform();

      if (!response.ok) {
        this.revertDrop(el);
        debugLog(`Failed to sort item: ${response.statusCode}`);
      }
    } catch (error) {
      this.revertDrop(el);
      debugLog('Failed to sort item due to request error', error);
    } finally {
      this.dragOriginSource = null;
      this.dragOriginNextSibling = null;
    }
  }

  protected buildData(el:Element, target:Element):FormData {
    const data = new FormData();

    if (this.positionModeValue === 'prev_id') {
      data.append('prev_id', this.resolveTargetPrevious(el) ?? '');
    } else {
      data.append('position', this.resolveTargetPosition(el, target).toString());
    }

    const targetConfig = this.targetConfigs.find((config) => config.container === target);
    const targetId = targetConfig?.targetId as string|undefined;

    if (targetId) {
      data.append('target_id', targetId.toString());
    }

    return data;
  }

  private canStartDrag(el:Element|null|undefined, handle:Element|null|undefined):boolean {
    if (!this.isDraggableElement(el)) {
      return false;
    }

    if (!this.handleValue) {
      return closestInteractiveElement(handle ?? null, el) == null;
    }

    return handle?.closest(this.handleSelectorValue) != null;
  }

  private isDraggableElement(el:Element|null|undefined):boolean {
    return el instanceof HTMLElement
      && el.getAttribute('data-empty-list-item') !== 'true'
      && el.dataset.draggableType !== undefined
      && el.dataset.dropUrl !== undefined;
  }

  // if the target has a container accessor, use that as the container instead of the element itself
  // we need this e.g. in Primer's borderbox component as we cannot add required data attributes to the ul element there
  private resolveContainerElement(target:HTMLElement):HTMLElement {
    const accessor = target.getAttribute('data-target-container-accessor');
    if (!accessor) {
      return target;
    }
    const container = target.querySelector<HTMLElement>(accessor);
    invariant(container, `Expected container element matching "${accessor}"`);
    return container;
  }

  // Returns the data-draggable-id of the element preceding el in its container,
  // or null if el is the first item (signals "move to top").
  private resolveTargetPrevious(el:Element):string|null {
    return el.previousElementSibling?.getAttribute('data-draggable-id') ?? null;
  }

  private resolveTargetPosition(el:Element, container:Element):number {
    let targetPosition = Array.from(container.children).indexOf(el);

    if (container.children.length > 0 && container.children[0].getAttribute('data-empty-list-item') === 'true') {
      // if the target container is empty, a list item showing an empty message might be shown
      // this should not be counted as a list item
      // thus we need to subtract 1 from the target position
      targetPosition -= 1;
    }

    return targetPosition + 1;
  }

  private ariaPressedTarget(el:Element):Element|null {
    if (!this.handleValue) return null;
    return el.querySelector(this.handleSelectorValue);
  }
}
