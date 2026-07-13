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
import { Directive, ElementRef, OnInit, inject } from '@angular/core';

declare global {
  interface GlobalEventHandlersEventMap {
    'op:dragscroll':CustomEvent<{x:number, y:number}>;
  }
}

@Directive({
  selector: 'op-drag-scroll',
  standalone: false,
})
export class OpDragScrollDirective implements OnInit {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);


  ngOnInit() {
    const element = this.elementRef.nativeElement;

    // Is mouse down?
    let mousedown = false;

    // Position of last mousedown
    let mousedownX:number; let
      mousedownY:number;

    // Mousedown: Potential drag start
    element.addEventListener('mousedown', (evt) => {
      setTimeout(() => {
        mousedown = true;
        mousedownX = evt.clientX;
        mousedownY = evt.clientY;
      }, 50, false);
    });

    // Mouseup: Potential drag stop
    element.addEventListener('mouseup', () => {
      mousedown = false;
    });

    // Mousemove: Report movement if mousedown
    element.addEventListener('mousemove', (evt) => {
      if (!mousedown) {
        return;
      }

      // Trigger drag scroll event
      element.dispatchEvent(
        new CustomEvent('op:dragscroll', {
          detail: {
            x: evt.clientX - mousedownX,
            y: evt.clientY - mousedownY,
          },
        }),
      );

      // Update last mouse position
      mousedownX = evt.clientX;
      mousedownY = evt.clientY;
    });
  }
}
