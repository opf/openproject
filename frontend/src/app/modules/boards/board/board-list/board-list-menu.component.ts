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

import { Component, Output, EventEmitter, Input } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { AuthorisationService } from 'core-app/modules/common/model-auth/model-auth.service';
import { OpModalService } from "core-app/modules/modal/modal.service";
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { Board } from "core-app/modules/boards/board/board";
import { BoardActionsRegistryService } from "core-app/modules/boards/board/board-actions/board-actions-registry.service";
import { OpContextMenuItem } from "core-components/op-context-menu/op-context-menu.types";
import { BoardService } from "core-app/modules/boards/board/board.service";
import { BoardActionService } from "core-app/modules/boards/board/board-actions/board-action.service";

@Component({
  selector: 'board-list-menu',
  templateUrl: './board-list-menu.component.html',
})
export class BoardListMenuComponent {
  @Input() board:Board;
  @Output() onRemove = new EventEmitter<void>();

  constructor(readonly opModalService:OpModalService,
              readonly authorisationService:AuthorisationService,
              private readonly querySpace:IsolatedQuerySpace,
              private readonly boardService:BoardService,
              private readonly boardActionRegistry:BoardActionsRegistryService,
              readonly I18n:I18nService) {
  }

  public get menuItems() {
    return async () => {
      const items:OpContextMenuItem[] = [
        {
          disabled: !this.canDelete,
          linkText: this.I18n.t('js.boards.lists.delete'),
          onClick: () => {
            this.onRemove.emit();
            return true;
          }
        }
      ];

      // Add action specific menu entries
      if (this.board.isAction) {
        const additional = await this.actionService.getAdditionalListMenuItems(this.query);
        return items.concat(additional);
      }

      return items;
    };
  }

  private get actionService():BoardActionService {
    return this.boardActionRegistry.get(this.board.actionAttribute!);
  }

  private get canManage() {
    return this.boardService.canManage(this.board);
  }

  public canDelete() {
    return this.canManage && !!this.query.delete;
  }

  private get query() {
    return this.querySpace.query.value!;
  }
}
