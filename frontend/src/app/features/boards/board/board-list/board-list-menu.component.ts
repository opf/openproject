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

import { ChangeDetectionStrategy, Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { Board } from 'core-app/features/boards/board/board';
import { BoardActionsRegistryService } from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';

@Component({
  selector: 'board-list-menu',
  templateUrl: './board-list-menu.component.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class BoardListMenuComponent {
  readonly opModalService = inject(OpModalService);
  readonly authorisationService = inject(AuthorisationService);
  private readonly querySpace = inject(IsolatedQuerySpace);
  private readonly boardService = inject(BoardService);
  private readonly boardActionRegistry = inject(BoardActionsRegistryService);
  readonly I18n = inject(I18nService);

  @Input() board:Board;

  @Output() onRemove = new EventEmitter<void>();

  public get menuItems() {
    return async () => {
      const items:OpContextMenuItem[] = [
        {
          disabled: !this.canDelete,
          linkText: this.I18n.t('js.boards.lists.delete'),
          onClick: () => {
            this.onRemove.emit();
            return true;
          },
        },
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
