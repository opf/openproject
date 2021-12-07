// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpContextMenuHandler } from 'core-app/shared/components/op-context-menu/op-context-menu-handler';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { StateService } from '@uirouter/core';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import { OPWPQuickAddModalComponent } from 'core-app/features/work-packages/components/op-wp-quick-add-modal/op-wp-quick-add-modal.component';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { EventContentArg } from '@fullcalendar/common';

export class TeamPlannerContextMenu extends OpContextMenuHandler {
  @InjectField() I18n:I18nService;

  @InjectField() state:StateService;

  @InjectField() modalService:OpModalService;

  protected items:OpContextMenuItem[] = this.buildItems();

  constructor(public injector:Injector,
    protected arg:unknown,
    protected $element:JQuery,
  ) {
    super(injector.get(OPContextMenuService));
  }

  public get locals() {
    return {
      contextMenuId: 'teamPlannerContextMenu',
      items: this.items,
    };
  }

  protected open(evt:JQuery.TriggeredEvent):void {
    this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  private buildItems():OpContextMenuItem[] {
    return [
      {
        // Configuration modal
        linkText: this.I18n.t('js.team_planner.context_menu.create_new'),
        onClick: () => {
          void this.state.go(
            `${splitViewRoute(this.state)}.new`,
            { tabIdentifier: 'overview' },
          );
          return true;
        },
      },
      {
        // Rename query shortcut
        linkText: this.I18n.t('js.team_planner.context_menu.add_existing'),
        onClick: () => {
          const modal = this.modalService.show(OPWPQuickAddModalComponent, this.injector);
          void modal
            .closingEvent
            .toPromise()
            .then((instance:OPWPQuickAddModalComponent) => {
              if (instance.selectedWorkPackage) {
                // TODO
                // void this.addWorkPackageToCell(instance.selectedWorkPackage, info);
              }
            });
          return true;
        },
      },
    ];
  }
}
