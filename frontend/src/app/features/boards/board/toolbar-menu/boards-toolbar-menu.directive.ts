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

import { Directive, Injector, inject, input } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpActionMenuItems } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-items';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { Board } from 'core-app/features/boards/board/board';
import { BoardConfigurationModalComponent } from 'core-app/features/boards/board/configuration-modal/board-configuration.modal';
import { selectableTitleIdentifier, triggerEditingEvent } from 'core-app/shared/components/editable-toolbar-title/editable-toolbar-title.component';

@Directive({
  // eslint-disable-next-line @angular-eslint/directive-selector
  selector: '[boardsToolbarMenu]',
})
export class BoardsToolbarMenuDirective extends OpActionMenuItems {
  readonly opModalService = inject(OpModalService);
  readonly injector = inject(Injector);
  readonly I18n = inject(I18nService);
  readonly http = inject(HttpClient);

  // eslint-disable-next-line @angular-eslint/no-input-rename
  readonly board = input.required<Board>({ alias: 'boardsToolbarMenu-resource' });

  protected buildItems():OpContextMenuItem[] {
    return [
      {
        linkText: this.I18n.t('js.toolbar.settings.configure_view'),
        octicon: 'gear',
        onClick: () => {
          this.opModalService.show(BoardConfigurationModalComponent, this.injector, { board: this.board() });

          return true;
        },
      },
      {
        linkText: this.I18n.t('js.toolbar.settings.page_settings'),
        octicon: 'pencil',
        onClick: () => {
          if (this.board().grid.updateImmediately) {
            document.querySelector(selectableTitleIdentifier)?.dispatchEvent(new CustomEvent(triggerEditingEvent, { bubbles: true }));
          }

          return true;
        },
      },
      { divider: true },
      {
        linkText: this.I18n.t('js.toolbar.settings.delete'),
        octicon: 'trash',
        scheme: 'danger',
        onClick: () => {
          const board = this.board();
          if (board.id
            && board.grid.delete
            && window.confirm(this.I18n.t('js.text_query_destroy_confirmation'))) {
            void this.http
              .delete(
                `/projects/${board.projectId}/boards/${board.id}`,
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
