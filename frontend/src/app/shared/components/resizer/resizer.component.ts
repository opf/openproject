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
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  HostListener,
  Input,
  OnDestroy,
  Output,
} from '@angular/core';

import { setBodyCursor } from 'core-app/shared/helpers/dom/set-window-cursor.helper';

export interface ResizeDelta {
  origin:UIEvent;

  // Absolute difference from start
  absolute:{
    x:number;
    y:number;
  };

  // Relative difference from last position
  relative:{
    x:number;
    y:number;
  };
}

@Component({
  selector: 'op-resizer',
  templateUrl: './resizer.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ResizerComponent implements OnDestroy {
  private startX:number;

  private startY:number;

  private oldX:number;

  private oldY:number;

  private newX:number;

  private newY:number;

  private mouseMoveHandler:EventListener;

  private mouseUpHandler:EventListener;

  @Output() resizeFinished:EventEmitter<ResizeDelta> = new EventEmitter<ResizeDelta>();

  @Output() resizeStarted:EventEmitter<ResizeDelta> = new EventEmitter<ResizeDelta>();

  @Output() move:EventEmitter<ResizeDelta> = new EventEmitter<ResizeDelta>();

  @Input() customHandler = false;

  @Input() cursorClass = 'nwse-resize';

  @Input() resizerClass = 'resizer';

  ngOnDestroy() {
    this.removeEventListener();
  }

  @HostListener('mousedown', ['$event'])
  @HostListener('touchstart', ['$event'])
  // public startResize(event:any) {
  public startResize(event:MouseEvent|TouchEvent) {
    event.preventDefault();
    event.stopPropagation();

    if (this.isMouseEvent(event) && event.button !== 0) {
      // Only handle primary mouse button clicks
      return;
    }

    const { x, y } = this.position(event);
    this.oldX = x;
    this.startX = x;
    this.newX = x;
    this.oldY = y;
    this.startY = y;
    this.newY = y;

    this.setResizeCursor();
    this.bindEventListener();
    this.resizeStarted.emit(this.buildDelta(event));
  }

  private position(event:MouseEvent|TouchEvent):{ x:number, y:number } {
    if (this.isMouseEvent(event)) {
      return { x: event.clientX, y: event.clientY };
    }

    return { x: event.touches[0].clientX, y: event.touches[0].clientY };
  }

  private isMouseEvent(event:MouseEvent|TouchEvent):event is MouseEvent {
    return event instanceof MouseEvent;
  }

  private onMouseUp(event:MouseEvent|TouchEvent) {
    this.setAutoCursor();
    this.removeEventListener();

    this.resizeFinished.emit(this.buildDelta(event));
  }

  private onMouseMove(event:MouseEvent|TouchEvent) {
    event.stopPropagation();

    this.oldX = this.newX;
    this.oldY = this.newY;

    const { x, y } = this.position(event);
    this.newX = x;
    this.newY = y;

    this.move.emit(this.buildDelta(event));
  }

  // Necessary to encapsulate this to be able to remove the event listener later
  private bindEventListener() {
    this.mouseMoveHandler = this.onMouseMove.bind(this);
    this.mouseUpHandler = this.onMouseUp.bind(this);

    window.addEventListener('mousemove', this.mouseMoveHandler);
    window.addEventListener('touchmove', this.mouseMoveHandler);
    window.addEventListener('mouseup', this.mouseUpHandler);
    window.addEventListener('touchend', this.mouseUpHandler);
  }

  private removeEventListener() {
    window.removeEventListener('touchmove', this.mouseMoveHandler);
    window.removeEventListener('mousemove', this.mouseMoveHandler);
    window.removeEventListener('mouseup', this.mouseUpHandler);
    window.removeEventListener('touchend', this.mouseUpHandler);
  }

  private setResizeCursor() {
    setBodyCursor(this.cursorClass, 'important');
  }

  private setAutoCursor() {
    setBodyCursor('auto');
  }

  private buildDelta(event:MouseEvent|TouchEvent):ResizeDelta {
    return {
      origin: event,
      absolute: {
        x: this.newX - this.startX,
        y: this.newY - this.startY,
      },
      relative: {
        x: this.newX - this.oldX,
        y: this.newY - this.oldY,
      },
    };
  }
}
