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

import { ChangeDetectionStrategy, Component, CUSTOM_ELEMENTS_SCHEMA, ElementRef, inject, input, output } from '@angular/core';
import { NgClass, NgTemplateOutlet } from '@angular/common';
import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { DynamicIconDirective } from 'core-app/shared/components/primer/dynamic-icon.directive';
import { generateId } from 'core-app/shared/helpers/dom-helpers';

/**
 * Renders context menu items as a Primer ActionMenu. The markup mirrors
 * `Primer::Alpha::ActionMenu` with `SubMenuItem`s; the `<action-menu>` element
 * from Primer ViewComponents supplies keyboard handling, focus zones and
 * submenu toggling.
 */
@Component({
  selector: 'op-action-menu',
  templateUrl: './op-action-menu.component.html',
  imports: [NgClass, NgTemplateOutlet, IconModule, DynamicIconDirective],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpActionMenuComponent {
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  readonly items = input.required<OpContextMenuItem[]>();
  readonly label = input.required<string>();

  /** Emits after an item's `onClick` handled the activation. */
  readonly activated = output<OpContextMenuItem>();

  readonly menuId = generateId('op-action-menu');

  get menuElement():ActionMenuElement {
    return this.host.nativeElement.querySelector<ActionMenuElement>('action-menu')!;
  }

  subMenuId(index:number):string {
    return `${this.menuId}-sub-${index}`;
  }

  handleClick(item:OpContextMenuItem, event:MouseEvent):void {
    if (item.disabled) {
      event.preventDefault();
      return;
    }

    if (item.onClick?.(event)) {
      event.preventDefault();
      this.activated.emit(item);
    }
  }

  // Primer ViewComponents 0.95 lets focus drop to the body when a submenu closes
  // while its parent stays open, and its focusout handler then closes the whole
  // menu. Remove once opf/primer_view_components#547 ships.
  refocusSubMenuItem(event:Event, itemId:string):void {
    if ((event as ToggleEvent).newState !== 'closed') {
      return;
    }

    if (this.menuElement.popoverElement?.matches(':popover-open')) {
      this.host.nativeElement.querySelector<HTMLElement>(`[id="${itemId}"]`)?.focus();
    }
  }
}
