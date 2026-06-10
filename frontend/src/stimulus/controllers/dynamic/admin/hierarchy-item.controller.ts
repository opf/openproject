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
import * as Turbo from '@hotwired/turbo';
import { useMeta } from 'stimulus-use';

export default class HierarchyItemController extends Controller {
  static metaNames = ['csrf-token'];
  declare readonly csrfToken:string;

  private currentHover:HTMLElement | null;

  connect() {
    useMeta(this, { suffix: false });
  }

  dragstart(event:DragEvent) {
    const element = dataNode(event.target);
    element.style.opacity = '0.4';

    if (event.dataTransfer) {
      event.dataTransfer.setDragImage(element, 25, 25);
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('application/dragkey', element.dataset.hierarchyItemId || '');
    }
  }

  dragenter(event:DragEvent) {
    this.currentHover = event.target as HTMLElement;
    event.preventDefault();
    event.stopPropagation();

    dataNode(event.target).classList.add('bgColor-accent-muted');
    return false;
  }

  dragleave(event:DragEvent) {
    if (event.target === this.currentHover) {
      dataNode(event.target).classList.remove('bgColor-accent-muted');
      event.preventDefault();
      event.stopPropagation();
    }
    return false;
  }

  dragend(event:DragEvent) {
    if (event.target === this.currentHover) {
      dataNode(event.target).classList.remove('bgColor-accent-muted');
      event.preventDefault();
      event.stopPropagation();
    }
    return false;
  }

  drop(event:DragEvent) {
    const targetElement = dataNode(event.target);

    if (event.dataTransfer) {
      const origin = event.dataTransfer.getData('application/dragkey');
      const originElement = document.querySelector<HTMLElement>(`[data-hierarchy-item-id='${origin}']`);
      if (!originElement) { return; }

      originElement.style.opacity = '1';

      if (targetElement.dataset.hierarchyItemId === originElement.dataset.hierarchyItemId) {
        return;
      }

      let targetSortOrder = Number(targetElement.dataset.sortOrder);
      if (targetElement.compareDocumentPosition(originElement) === Node.DOCUMENT_POSITION_PRECEDING) {
        targetSortOrder += 1;
      }

      this.#updateSortOrder(originElement, targetSortOrder);
    }
  }

  #updateSortOrder(originElement:HTMLElement, sortOrder:number | string):void {
    const { frameId = '', indexUrl = '', moveUrl = '' } = originElement.dataset;

    fetch(new URL(moveUrl), {
      body: new URLSearchParams([['new_sort_order', sortOrder.toString()]]),
      method: 'POST',
      credentials: 'include',
      headers: [
        ['Content-Type', 'application/x-www-form-urlencoded;charset=UTF-8'],
        ['X-CSRF-Token', this.csrfToken],
      ],
      redirect: 'manual',
    }).then(() => {
      Turbo.visit(indexUrl, { frame: frameId });
    }).catch(() => {});
  }
}

function dataNode(node:EventTarget | null):HTMLElement {
  if (!(node instanceof Element)) throw new Error('Cannot handle drag and drop of non HTML element');

  return node.closest('[data-hierarchy-item-id]')!;
}
