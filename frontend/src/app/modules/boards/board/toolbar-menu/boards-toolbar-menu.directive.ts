//-- copyright
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { Directive, ElementRef, Injector, Input } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { OpContextMenuTrigger } from 'core-components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { OPContextMenuService } from 'core-components/op-context-menu/op-context-menu.service';
import { OpModalService } from "core-app/modules/modal/modal.service";
import { Board } from "core-app/modules/boards/board/board";
import { BoardConfigurationModal } from "core-app/modules/boards/board/configuration-modal/board-configuration.modal";
import { BoardService } from "core-app/modules/boards/board/board.service";
import { StateService } from "@uirouter/core";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { triggerEditingEvent } from "core-app/modules/common/editable-toolbar-title/editable-toolbar-title.component";

@Directive({
  selector: '[boardsToolbarMenu]'
})
export class BoardsToolbarMenuDirective extends OpContextMenuTrigger {
  @Input('boardsToolbarMenu-resource') public board:Board;

  public text = {
    deleteSuccessful: this.I18n.t('js.notice_successful_delete'),
  };

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly opModalService:OpModalService,
              readonly boardService:BoardService,
              readonly Notifications:NotificationsService,
              readonly State:StateService,
              readonly injector:Injector,
              readonly I18n:I18nService) {

    super(elementRef, opContextMenu);
  }

  public get locals() {
    return {
      contextMenuId: 'boardsToolbarMenu',
      items: this.items
    };
  }

  protected open(evt:JQuery.TriggeredEvent) {
    this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  private buildItems() {
    this.items = [
      {
        // Configuration modal
        linkText: this.I18n.t('js.toolbar.settings.configure_view'),
        icon: 'icon-settings',
        onClick: ($event:JQuery.TriggeredEvent) => {
          this.opContextMenu.close();
          this.opModalService.show(BoardConfigurationModal, this.injector, { board: this.board });

          return true;
        }
      },
      {
        // Rename query shortcut
        linkText: this.I18n.t('js.toolbar.settings.page_settings'),
        icon: 'icon-edit',
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (this.board.grid.updateImmediately) {
            jQuery(`.toolbar-container .editable-toolbar-title--input`).trigger(triggerEditingEvent);
          }

          return true;
        }
      },
      {
        // Delete query
        linkText: this.I18n.t('js.toolbar.settings.delete'),
        icon: 'icon-delete',
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (this.board.grid.delete &&
            window.confirm(this.I18n.t('js.text_query_destroy_confirmation'))) {
            this.boardService
              .delete(this.board)
              .then(() => {
                this.State.go('boards.list', { flash_message: { type: 'success', message: this.text.deleteSuccessful } });
              });
          }

          return true;
        }
      }
    ];
  }
}
