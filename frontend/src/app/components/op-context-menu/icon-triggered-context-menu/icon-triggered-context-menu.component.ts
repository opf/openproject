//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {ChangeDetectorRef, Component, ElementRef, Injector, Input} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {OpContextMenuTrigger} from 'core-components/op-context-menu/handlers/op-context-menu-trigger.directive';
import {OPContextMenuService} from 'core-components/op-context-menu/op-context-menu.service';
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {OpContextMenuItem} from "core-components/op-context-menu/op-context-menu.types";

@Component({
  selector: 'icon-triggered-context-menu',
  templateUrl: './icon-triggered-context-menu.component.html',
  styleUrls: ['./icon-triggered-context-menu.component.sass']
})
export class IconTriggeredContextMenuComponent extends OpContextMenuTrigger {
  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly opModalService:OpModalService,
              readonly injector:Injector,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService) {

    super(elementRef, opContextMenu);
  }

  @Input('menu-items') menuItems:Function;

  protected async open(evt:JQuery.TriggeredEvent) {
    this.items = await this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(evt:JQuery.TriggeredEvent) {
    let additionalPositionArgs = {
      my: 'right top',
      at: 'right bottom'
    };

    let position = super.positionArgs(evt);
    _.assign(position, additionalPositionArgs);

    return position;
  }

  private async buildItems() {
    let items:OpContextMenuItem[] = [];

    // Add action specific menu entries
    if (this.menuItems) {
      const additional = await this.menuItems();
      return items.concat(additional);
    }

    return items;
  }
}
