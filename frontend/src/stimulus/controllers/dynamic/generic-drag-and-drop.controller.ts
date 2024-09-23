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

import * as Turbo from '@hotwired/turbo';
import { Controller } from '@hotwired/stimulus';
import { Drake } from 'dragula';
import { debugLog } from 'core-app/shared/helpers/debug_output';

interface TargetConfig {
  container:Element;
  allowedDragType:string|null;
  targetId:string|null;
}

export default class extends Controller {
  drake:Drake|undefined;
  targetConfigs:TargetConfig[];

  containerTargets:Element[];

  connect() {
    this.initDrake();
  }

  initDrake() {
    this.setContainerTargetsAndConfigs();

    // reinit drake if it already exists
    if (this.drake) {
      this.drake.destroy();
    }

    this.drake = dragula(
      this.containerTargets,
      {
        moves: (_el, _source, handle, _sibling) => !!handle?.classList.contains('octicon-grabber'),
        accepts: (el:Element, target:Element, source:Element, sibling:Element) => this.accepts(el, target, source, sibling),
        revertOnSpill: true, // enable reverting of elements if they are dropped outside of a valid target
      },
    )
      // eslint-disable-next-line @typescript-eslint/no-misused-promises
      .on('drag', this.drag.bind(this))
      // eslint-disable-next-line @typescript-eslint/no-misused-promises
      .on('drop', this.drop.bind(this));

    // Setup autoscroll
    void window.OpenProject.getPluginContext().then((pluginContext) => {
      // eslint-disable-next-line no-new
      new pluginContext.classes.DomAutoscrollService(
        [
          document.getElementById('content-body') as HTMLElement,
        ],
        {
          margin: 25,
          maxSpeed: 10,
          scrollWhenOutside: true,
          autoScroll: () => this.drake?.dragging,
        },
      );
    });
  }

  reInitDrakeContainers() {
    this.setContainerTargetsAndConfigs();
    if (this.drake) {
      this.drake.containers = this.containerTargets;
    }
  }

  setContainerTargetsAndConfigs():void {
    const rawTargets = Array.from(
      this.element.querySelectorAll('[data-is-drag-and-drop-target="true"]'),
    );
    this.targetConfigs = [];
    let processedTargets:Element[] = [];

    rawTargets.forEach((target:Element) => {
      const targetConfig:TargetConfig = {
        container: target,
        allowedDragType: target.getAttribute('data-target-allowed-drag-type'),
        targetId: target.getAttribute('data-target-id'),
      };

      // if the target has a container accessor, use that as the container instead of the element itself
      // we need this e.g. in Primer's boderbox component as we cannot add required data attributes to the ul element there
      const containerAccessor = target.getAttribute('data-target-container-accessor');

      if (containerAccessor) {
        target = target.querySelector(containerAccessor) as Element;
        targetConfig.container = target;
      }

      // we need to save the targetConfigs separately as we need to pass the pure container elements to drake
      // but need the configuration of the targets when dropping elements
      this.targetConfigs.push(targetConfig);

      processedTargets = processedTargets.concat(target);
    });

    this.containerTargets = processedTargets;
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

  drag(_:Element, _source:Element|null) {
    // discover new target containers if they have been added to the DOM via Turbo streams
    this.reInitDrakeContainers();
  }

  async drop(el:Element, target:Element, _source:Element|null, _sibling:Element|null) {
    const dropUrl = el.getAttribute('data-drop-url');

    let targetPosition = Array.from(target.children).indexOf(el);
    if (target.children.length > 0 && target.children[0].getAttribute('data-empty-list-item') === 'true') {
      // if the target container is empty, a list item showing an empty message might be shown
      // this should not be counted as a list item
      // thus we need to subtract 1 from the target position
      targetPosition -= 1;
    }

    const targetConfig = this.targetConfigs.find((config) => config.container === target);
    const targetId = targetConfig?.targetId as string|undefined;

    const data = new FormData();

    data.append('position', (targetPosition + 1).toString());

    if (targetId) {
      data.append('target_id', targetId.toString());
    }

    if (dropUrl) {
      const response = await fetch(dropUrl, {
        method: 'PUT',
        body: data,
        headers: {
          'X-CSRF-Token': (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement).content,
          Accept: 'text/vnd.turbo-stream.html',
        },
        credentials: 'same-origin',
      });

      if (!response.ok) {
        debugLog('Failed to sort item');
      } else {
        const text = await response.text();
        Turbo.renderStreamMessage(text);
        // reinit drake containers as the DOM will be updated by Turbo streams
        // otherwise the DOM references in the Drake instance will be outdated
        setTimeout(() => this.reInitDrakeContainers(), 100);
      }
    }

    if (this.drake) {
      this.drake.cancel(true); // necessary to prevent "copying" behaviour
    }
  }

  disconnect() {
    if (this.drake) {
      this.drake.destroy();
    }
  }
}
