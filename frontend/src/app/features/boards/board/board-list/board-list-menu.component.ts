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

import { ChangeDetectorRef, Component, EventEmitter, Output, inject, input } from '@angular/core';
import { takeUntilDestroyed, toObservable } from '@angular/core/rxjs-interop';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { Board } from 'core-app/features/boards/board/board';
import { BoardActionsRegistryService } from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';
import { distinctUntilChanged, EMPTY, map, merge, switchMap } from 'rxjs';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'board-list-menu',
  templateUrl: './board-list-menu.component.html',
  standalone: false,
})
export class BoardListMenuComponent {
  readonly opModalService = inject(OpModalService);
  readonly authorisationService = inject(AuthorisationService);
  private readonly apiV3Service = inject(ApiV3Service);
  private readonly cdRef = inject(ChangeDetectorRef);
  private readonly querySpace = inject(IsolatedQuerySpace);
  private readonly boardService = inject(BoardService);
  private readonly boardActionRegistry = inject(BoardActionsRegistryService);
  readonly I18n = inject(I18nService);

  readonly board = input.required<Board>();

  // eslint-disable-next-line @angular-eslint/no-output-on-prefix
  @Output() onRemove = new EventEmitter<void>();

  constructor() {
    const boardPermission$ = toObservable(this.board).pipe(
      switchMap(({ id }) => id ? this.apiV3Service.boards.id(id).observe() : EMPTY),
      map((board) => this.boardService.canManage(board)),
      distinctUntilChanged(),
    );

    merge(this.querySpace.query.changes$(), boardPermission$)
      .pipe(takeUntilDestroyed())
      .subscribe(() => this.cdRef.markForCheck());
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
          },
        },
      ];

      // Add action specific menu entries
      if (this.board().isAction) {
        const additional = await this.actionService.getAdditionalListMenuItems(this.query);
        return items.concat(additional);
      }

      return items;
    };
  }

  private get actionService():BoardActionService {
    return this.boardActionRegistry.get(this.board().actionAttribute!);
  }

  private get canManage() {
    return this.boardService.canManage(this.board());
  }

  public canDelete() {
    return this.canManage && !!this.querySpace.query.value?.delete;
  }

  private get query() {
    return this.querySpace.query.value!;
  }
}
