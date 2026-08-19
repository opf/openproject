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

import { Directive, Injector, Input, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpContextMenuTrigger } from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { Board } from 'core-app/features/boards/board/board';
import { BoardConfigurationModalComponent } from 'core-app/features/boards/board/configuration-modal/board-configuration.modal';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { StateService } from '@uirouter/core';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { selectableTitleIdentifier, triggerEditingEvent } from 'core-app/shared/components/editable-toolbar-title/editable-toolbar-title.component';

@Directive({
  selector: '[boardsToolbarMenu]',
  standalone: false,
})
export class BoardsToolbarMenuDirective extends OpContextMenuTrigger {
  readonly opModalService = inject(OpModalService);
  readonly boardService = inject(BoardService);
  readonly Notifications = inject(ToastService);
  readonly State = inject(StateService);
  readonly injector = inject(Injector);
  readonly I18n = inject(I18nService);
  readonly http = inject(HttpClient);

  // eslint-disable-next-line @angular-eslint/no-input-rename
  @Input('boardsToolbarMenu-resource') public board:Board;

  public get locals() {
    return {
      contextMenuId: 'boardsToolbarMenu',
      items: this.items,
    };
  }

  protected open(evt:Event) {
    this.buildItems();
    this.opContextMenu.show(this, evt);
  }

  private buildItems() {
    this.items = [
      {
        // Configuration modal
        linkText: this.I18n.t('js.toolbar.settings.configure_view'),
        icon: 'icon-settings',
        onClick: () => {
          this.opContextMenu.close();
          this.opModalService.show(BoardConfigurationModalComponent, this.injector, { board: this.board });

          return true;
        },
      },
      {
        // Rename query shortcut
        linkText: this.I18n.t('js.toolbar.settings.page_settings'),
        icon: 'icon-edit',
        onClick: () => {
          if (this.board.grid.updateImmediately) {
            document.querySelector(selectableTitleIdentifier)?.dispatchEvent(new CustomEvent(triggerEditingEvent, { bubbles: true }));
          }

          return true;
        },
      },
      {
        // Delete query
        linkText: this.I18n.t('js.toolbar.settings.delete'),
        icon: 'icon-delete',
        onClick: () => {
          if (this.board.id
            && this.board.grid.delete
            && window.confirm(this.I18n.t('js.text_query_destroy_confirmation'))) {
            void this.http
              .delete(
                `/projects/${this.board.projectId}/boards/${this.board.id}`,
                { responseType: 'json' },
              )
              .subscribe(
                (response:{ redirect_url:string }) => {
                  window.location.href = response.redirect_url;
                },
              );
          }

          return true;
        },
      },
    ];
  }
}
