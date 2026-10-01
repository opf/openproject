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

import { computePosition, ComputePositionReturn, flip, Placement, shift } from '@floating-ui/dom';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

/**
 * Interface passed to CM service to open a particular context menu.
 * This will often be a trigger component, but does not have to be.
 */
export abstract class OpContextMenuHandler extends UntilDestroyedMixin {
  protected element:HTMLElement;

  protected items:OpContextMenuItem[] = [];

  protected placement:Placement = 'bottom-start';

  constructor(readonly opContextMenu:OPContextMenuService) {
    super();
  }

  /**
   * Called when the service closes this context menu
   *
   * @param focus Focus on the trigger again
   */
  public onClose(focus = true) {
    if (focus) {
      this.afterFocusOn.focus();
    }
  }

  public onOpen(menu:HTMLElement) {
    menu.querySelector<HTMLElement>('.menu-item')?.focus();
  }

  /**
   * Compute position for Floating UI.
   *
   * @param {Event} openerEvent
   */
  public computePosition(floating:HTMLElement, openerEvent:Event):Promise<ComputePositionReturn> {
    const reference = openerEvent.target as HTMLElement;
    return computePosition(reference, floating, {
      placement: this.placement,
      middleware: [
        flip(),
        shift({ padding: 10 }),
      ],
    });
  }

  /**
   * Get the locals passed to the op-context-menu component
   */
  public get locals():{ showAnchorRight?:boolean, contextMenuId?:string, items:OpContextMenuItem[] } {
    return {
      items: this.items,
    };
  }

  /**
   * Open this context menu
   */
  protected open(evt:Event):void {
    this.opContextMenu.show(this, evt);
  }

  protected get afterFocusOn():HTMLElement {
    const focusableSelector = 'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

    if (this.element.matches(focusableSelector)) {
      return this.element;
    }

    return this.element.querySelector<HTMLElement>(focusableSelector) ?? this.element;
  }
}
