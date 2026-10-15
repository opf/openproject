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

const COPIED_FEEDBACK = 1500;
const EDGE_MARGIN = 8;
const MIN_WIDTH = 320;
const MIN_HEIGHT = 240;
const GEOMETRY_PROPERTIES = ['left', 'top', 'right', 'bottom', 'width', 'height', 'maxHeight'] as const;

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
  static targets = ['pane', 'raw', 'copyLabel', 'applyFailed', 'applyFailedMessage'];

  static values = {
    closeForm: String,
    copy: String,
    copied: String,
  };

  declare readonly paneTarget:HTMLElement;
  declare readonly rawTarget:HTMLTemplateElement;
  declare readonly copyLabelTarget:HTMLElement;
  declare readonly closeFormValue:string;
  declare readonly copyValue:string;
  declare readonly copiedValue:string;

  private dragOffset:{ x:number; y:number }|null = null;
  private resizeStart:ResizeStart|null = null;
  private copyTimer:ReturnType<typeof setTimeout>|null = null;

  private readonly onDragMove = (event:PointerEvent) => this.drag(event);
  private readonly onResizeMove = (event:PointerEvent) => this.resize(event);
  private readonly onPointerUp = () => this.endPointerAction();

  connect():void {
    if (rememberedGeometry) {
      Object.assign(this.paneTarget.style, rememberedGeometry);
    }
    this.paneTarget.focus({ preventScroll: true });
  }

  disconnect():void {
    this.endPointerAction();
    this.clearCopyTimer();
    rememberedGeometry = this.paneTarget.style.left ? this.geometry() : null;
  }

  beginDrag(event:PointerEvent):void {
    if ((event.target as Element).closest('button')) {
      return;
    }

    const rect = this.paneTarget.getBoundingClientRect();
    this.dragOffset = { x: event.clientX - rect.left, y: event.clientY - rect.top };
    this.listen(this.onDragMove);
    event.preventDefault();
  }

  // Resizing pins the pane to explicit coordinates first, so a right or bottom handle
  // grows it in place and a left handle moves the left edge only.
  beginResize(event:PointerEvent):void {
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
    this.listen(this.onResizeMove);
    event.preventDefault();
  }

  close():void {
    const form = document.getElementById(this.closeFormValue);
    if (form instanceof HTMLFormElement) {
      form.requestSubmit();
    } else {
      this.element.remove();
    }
  }

  async copy():Promise<void> {
    await navigator.clipboard.writeText(this.rawTarget.content.textContent ?? '');
    this.copyLabelTarget.textContent = this.copiedValue;
    this.clearCopyTimer();
    this.copyTimer = setTimeout(() => {
      this.copyLabelTarget.textContent = this.copyValue;
      this.copyTimer = null;
    }, COPIED_FEEDBACK);
  }

  private drag(event:PointerEvent):void {
    if (!this.dragOffset) {
      return;
    }

    const rect = this.paneTarget.getBoundingClientRect();
    const maxLeft = Math.max(EDGE_MARGIN, window.innerWidth - rect.width - EDGE_MARGIN);
    const maxTop = Math.max(EDGE_MARGIN, window.innerHeight - rect.height - EDGE_MARGIN);

    this.pin(
      clamp(event.clientX - this.dragOffset.x, EDGE_MARGIN, maxLeft),
      clamp(event.clientY - this.dragOffset.y, EDGE_MARGIN, maxTop),
    );
  }

  private resize(event:PointerEvent):void {
    if (!this.resizeStart) {
      return;
    }

    const { x, y, left, top, width, height, edge } = this.resizeStart;
    const { style } = this.paneTarget;

    if (edge.endsWith('left')) {
      const newWidth = clamp(width - (event.clientX - x), MIN_WIDTH, left + width - EDGE_MARGIN);
      this.pin(left + width - newWidth, top);
      style.width = `${newWidth}px`;
    } else {
      style.width = `${clamp(width + (event.clientX - x), MIN_WIDTH, window.innerWidth - left - EDGE_MARGIN)}px`;
    }

    if (edge.startsWith('bottom')) {
      style.height = `${clamp(height + (event.clientY - y), MIN_HEIGHT, window.innerHeight - top - EDGE_MARGIN)}px`;
      style.maxHeight = 'none';
    }
  }

  private pin(left:number, top:number):void {
    Object.assign(this.paneTarget.style, { left: `${left}px`, top: `${top}px`, right: 'auto', bottom: 'auto' });
  }

  private geometry():Geometry {
    const { style } = this.paneTarget;
    return Object.fromEntries(GEOMETRY_PROPERTIES.map((property) => [property, style[property]]));
  }

  private listen(onMove:(event:PointerEvent) => void):void {
    window.addEventListener('pointermove', onMove);
    window.addEventListener('pointerup', this.onPointerUp);
  }

  private endPointerAction():void {
    this.dragOffset = null;
    this.resizeStart = null;
    window.removeEventListener('pointermove', this.onDragMove);
    window.removeEventListener('pointermove', this.onResizeMove);
    window.removeEventListener('pointerup', this.onPointerUp);
  }

  private clearCopyTimer():void {
    if (this.copyTimer) {
      clearTimeout(this.copyTimer);
      this.copyTimer = null;
    }
  }
}
