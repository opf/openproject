//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {ChangeDetectorRef, Directive, ElementRef, Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {OpContextMenuTrigger} from 'core-components/op-context-menu/handlers/op-context-menu-trigger.directive';
import {OPContextMenuService} from 'core-components/op-context-menu/op-context-menu.service';
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {BoardListComponent} from "core-app/modules/boards/board/board-list/board-list.component";
import {Board} from "core-app/modules/boards/board/board";
import {BoardActionsRegistryService} from "core-app/modules/boards/board/board-actions/board-actions-registry.service";
import {OpContextMenuItem} from "core-components/op-context-menu/op-context-menu.types";

@Directive({
  selector: '[boardListDropdown]'
})
export class BoardListDropdownMenuDirective extends OpContextMenuTrigger {
  private board:Board;

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly opModalService:OpModalService,
              readonly authorisationService:AuthorisationService,
              readonly boardList:BoardListComponent,
              readonly injector:Injector,
              readonly querySpace:IsolatedQuerySpace,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService,
              readonly boardActions:BoardActionsRegistryService) {

    super(elementRef, opContextMenu);
    this.board = this.boardList.board;
  }

  protected async open(evt:JQueryEventObject) {
    this.items = await this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(evt:JQueryEventObject) {
    let additionalPositionArgs = {
      my: 'right top',
      at: 'right bottom'
    };

    let position = super.positionArgs(evt);
    _.assign(position, additionalPositionArgs);

    return position;
  }

  private async buildItems() {
    let items:OpContextMenuItem[] = [
      {
        disabled: !this.boardList.canDelete,
        linkText: this.I18n.t('js.boards.lists.delete'),
        onClick: () => {
          this.boardList.deleteList();
          return true;
        }
      }
    ];

    // Add action specific menu entries
    if (this.board.isAction) {
      const actionService = this.boardActions.get(this.board.actionAttribute!);
      const query = this.querySpace.query.value!;

      const additional = await actionService.getAdditionalListMenuItems(query);
      return items.concat(additional);
    }

    return items;
  }
}
