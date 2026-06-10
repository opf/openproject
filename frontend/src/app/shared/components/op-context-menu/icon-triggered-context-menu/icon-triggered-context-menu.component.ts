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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  OpContextMenuTrigger,
} from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

@Component({
  selector: 'icon-triggered-context-menu',
  templateUrl: './icon-triggered-context-menu.component.html',
  styleUrls: ['./icon-triggered-context-menu.component.sass'],
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class IconTriggeredContextMenuComponent extends OpContextMenuTrigger {
  readonly opModalService = inject(OpModalService);
  readonly injector = inject(Injector);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly I18n = inject(I18nService);

  override readonly placement = 'bottom-end';

  @Input() menuItemsFactory:() => Promise<OpContextMenuItem[]>;
  @Input() customAriaLabel:string = this.I18n.t('js.label_open_menu');

  protected open(evt:Event):void {
    void this.openContextMenu(evt);
  }

  private async openContextMenu(evt:Event):Promise<void> {
    this.items = await this.buildItems();
    this.cdRef.markForCheck();
    this.opContextMenu.show(this, evt);
  }

  private async buildItems() {
    const items:OpContextMenuItem[] = [];

    // Add action specific menu entries
    if (this.menuItemsFactory) {
      const additional = await this.menuItemsFactory();
      return items.concat(additional);
    }

    return items;
  }
}
