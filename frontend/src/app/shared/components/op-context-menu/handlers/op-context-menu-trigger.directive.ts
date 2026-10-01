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

import { AfterViewInit, Directive, ElementRef, inject } from '@angular/core';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpContextMenuHandler } from 'core-app/shared/components/op-context-menu/op-context-menu-handler';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import Mousetrap from 'mousetrap';
import { computePosition, ComputePositionReturn, flip, shift } from '@floating-ui/dom';

@Directive({
  selector: '[opContextMenuTrigger]',
  standalone: false,
})
export class OpContextMenuTrigger extends OpContextMenuHandler implements AfterViewInit {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly opContextMenu:OPContextMenuService;

  protected element:HTMLElement;

  protected items:OpContextMenuItem[] = [];

  constructor() {
    const opContextMenu = inject(OPContextMenuService);

    super(opContextMenu);

    this.opContextMenu = opContextMenu;
  }

  ngAfterViewInit():void {
    this.element = this.elementRef.nativeElement;

    // Open by clicking the element
    this.element.addEventListener('click', (evt) => {
      evt.preventDefault();

      // When clicking the same trigger twice, close the element instead.
      if (this.opContextMenu.isActive(this)) {
        this.opContextMenu.close();
      } else {
        this.open(evt);
      }
    });

    // Open with keyboard combination as well
    Mousetrap(this.element).bind('shift+alt+f10', (evt:any) => {
      this.open(evt);
    });
  }

  public computePosition(floating:HTMLElement, openerEvent:Event):Promise<ComputePositionReturn> {
    return computePosition(this.element, floating, {
      placement: this.placement,
      middleware: [
        flip(),
        shift({ padding: 10 }),
      ],
    });
  }
}
