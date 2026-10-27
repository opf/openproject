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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import { closestDragBlockingElement } from 'core-stimulus/helpers/interactive-element-helper';

const EDGE_MARGIN = 8;
const MIN_WIDTH = 320;
const MIN_HEIGHT = 240;
const GEOMETRY_PROPERTIES = ['left', 'top', 'right', 'bottom', 'width', 'height', 'maxWidth', 'maxHeight'] as const;

type Geometry = Partial<Record<typeof GEOMETRY_PROPERTIES[number], string>>;

interface ResizeStart {
  x:number;
  y:number;
  left:number;
  top:number;
  width:number;
  height:number;
  edge:string;
}

// A new run replaces the whole pane element, so the place the user moved it to outlives the controller.
let rememberedGeometry:Geometry|null = null;

const clamp = (value:number, min:number, max:number) => Math.min(Math.max(min, value), max);

export default class AiTextTransformPaneController extends Controller<HTMLElement> {
  static targets = ['pane'];

  static values = {
    closeForm: String,
  };

  declare readonly paneTarget:HTMLElement;
  declare readonly closeFormValue:string;

  private dragOffset:{ x:number; y:number }|null = null;
  private resizeStart:ResizeStart|null = null;
  private pointerListeners:AbortController|null = null;

  connect():void {
    if (rememberedGeometry) {
      Object.assign(this.paneTarget.style, rememberedGeometry);
      this.keepInViewport();
    }
    this.paneTarget.focus({ preventScroll: true });
  }

  disconnect():void {
    this.endPointerAction();
    rememberedGeometry = this.pinned ? this.geometry() : null;
  }

  beginDrag(event:PointerEvent):void {
    if (event.button !== 0 || closestDragBlockingElement(event.target as Element, event.currentTarget as Element)) {
      return;
    }

    const rect = this.paneTarget.getBoundingClientRect();
    this.dragOffset = { x: event.clientX - rect.left, y: event.clientY - rect.top };
    this.listen((move) => this.drag(move));
    event.preventDefault();
  }

  beginResize(event:PointerEvent):void {
    if (event.button !== 0) {
      return;
    }

    const rect = this.paneTarget.getBoundingClientRect();
    this.resizeStart = {
      x: event.clientX,
      y: event.clientY,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      edge: (event.currentTarget as HTMLElement).dataset.edge ?? 'bottom-right',
    };
    this.pin(rect.left, rect.top);
    this.listen((move) => this.resize(move));
    event.preventDefault();
  }

  keepInViewport():void {
    if (this.pinned) {
      const rect = this.paneTarget.getBoundingClientRect();
      this.pinInViewport(rect.left, rect.top);
    }
  }

  close(event?:Event):void {
    event?.stopPropagation();
    const form = document.getElementById(this.closeFormValue);
    if (form instanceof HTMLFormElement) {
      form.requestSubmit();
    } else {
      this.element.remove();
    }
  }

  private get pinned():boolean {
    return this.paneTarget.style.left !== '';
  }

  private drag(event:PointerEvent):void {
    if (this.dragOffset) {
      this.pinInViewport(event.clientX - this.dragOffset.x, event.clientY - this.dragOffset.y);
    }
  }

  private resize(event:PointerEvent):void {
    if (!this.resizeStart) {
      return;
    }

    const { x, y, left, top, width, height, edge } = this.resizeStart;
    const { style } = this.paneTarget;
    style.maxWidth = `calc(100vw - ${2 * EDGE_MARGIN}px)`;

    if (edge.endsWith('left')) {
      const newWidth = clamp(width - (event.clientX - x), MIN_WIDTH, left + width - EDGE_MARGIN);
      this.pin(left + width - newWidth, top);
      style.width = `${newWidth}px`;
    } else {
      style.width = `${clamp(width + (event.clientX - x), MIN_WIDTH, window.innerWidth - left - EDGE_MARGIN)}px`;
    }

    if (edge.startsWith('bottom')) {
      style.height = `${clamp(height + (event.clientY - y), MIN_HEIGHT, window.innerHeight - top - EDGE_MARGIN)}px`;
      style.maxHeight = `calc(100vh - ${2 * EDGE_MARGIN}px)`;
    }
  }

  private pinInViewport(left:number, top:number):void {
    const { width, height } = this.paneTarget.getBoundingClientRect();
    const maxLeft = Math.max(EDGE_MARGIN, window.innerWidth - width - EDGE_MARGIN);
    const maxTop = Math.max(EDGE_MARGIN, window.innerHeight - height - EDGE_MARGIN);

    this.pin(clamp(left, EDGE_MARGIN, maxLeft), clamp(top, EDGE_MARGIN, maxTop));
  }

  private pin(left:number, top:number):void {
    Object.assign(this.paneTarget.style, { left: `${left}px`, top: `${top}px`, right: 'auto', bottom: 'auto' });
  }

  private geometry():Geometry {
    const { style } = this.paneTarget;
    return Object.fromEntries(GEOMETRY_PROPERTIES.map((property) => [property, style[property]]));
  }

  private listen(onMove:(event:PointerEvent) => void):void {
    this.pointerListeners?.abort();
    this.pointerListeners = new AbortController();
    const { signal } = this.pointerListeners;
    const end = () => this.endPointerAction();

    window.addEventListener('pointermove', onMove, { signal });
    window.addEventListener('pointerup', end, { signal });
    window.addEventListener('pointercancel', end, { signal });
  }

  private endPointerAction():void {
    this.pointerListeners?.abort();
    this.pointerListeners = null;
    this.dragOffset = null;
    this.resizeStart = null;
  }
}
