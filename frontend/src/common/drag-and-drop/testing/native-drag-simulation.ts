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

// Test helper: drives Pragmatic Drag and Drop with real native DragEvents,
// so specs exercise the actual adapters (draggable/dropTarget registration,
// hitbox data, stickiness) instead of mocked callbacks.
//
// Pragmatic postpones the drag start and throttles drag updates by one
// animation frame, so every step awaits a frame before returning.

export interface Point {
  x:number;
  y:number;
}

export function centerOf(element:Element):Point {
  const rect = element.getBoundingClientRect();

  return { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2 };
}

// A point inside the element, close to the given edge (25% from it), so the
// closest-edge hitbox resolves deterministically to that edge.
export function towardsEdgeOf(element:Element, edge:'top'|'bottom'|'left'|'right'):Point {
  const rect = element.getBoundingClientRect();
  const center = centerOf(element);

  switch (edge) {
    case 'top':
      return { x: center.x, y: rect.top + rect.height / 4 };
    case 'bottom':
      return { x: center.x, y: rect.bottom - rect.height / 4 };
    case 'left':
      return { x: rect.left + rect.width / 4, y: center.y };
    case 'right':
      return { x: rect.right - rect.width / 4, y: center.y };
    default:
      return center;
  }
}

function nextFrame():Promise<void> {
  return new Promise((resolve) => {
    requestAnimationFrame(() => resolve());
  });
}

export class NativeDragSimulation {
  private dataTransfer = new DataTransfer();

  constructor(private source:Element) {}

  async start(point:Point = centerOf(this.source)):Promise<void> {
    this.dispatch('dragstart', this.source, point);
    await nextFrame();
  }

  async dragOver(target:Element, point:Point = centerOf(target)):Promise<void> {
    this.dispatch('dragenter', target, point);
    this.dispatch('dragover', target, point);
    await nextFrame();
  }

  async drop(target:Element, point:Point = centerOf(target)):Promise<void> {
    await this.dragOver(target, point);
    this.dispatch('drop', target, point);
    await this.finish();
  }

  // A drag abandoned without a drop (e.g. released outside every target,
  // or cancelled with Escape): the browser only fires dragend on the source.
  async cancel():Promise<void> {
    this.dispatch('dragend', this.source, centerOf(this.source));
    await this.finish();
  }

  private async finish():Promise<void> {
    await nextFrame();
    // Pragmatic mounts a "honey pot" element over the last pointer position
    // after a drag to swallow phantom pointer events; a pointer move removes
    // it so it cannot shadow elementFromPoint checks of a later drag.
    window.dispatchEvent(new PointerEvent('pointermove', { clientX: 0, clientY: 0, bubbles: true }));
    await nextFrame();
  }

  private dispatch(type:string, target:Element, point:Point):void {
    target.dispatchEvent(new DragEvent(type, {
      bubbles: true,
      cancelable: true,
      composed: true,
      clientX: point.x,
      clientY: point.y,
      dataTransfer: this.dataTransfer,
    }));
  }
}
