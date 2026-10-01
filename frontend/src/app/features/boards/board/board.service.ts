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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, inject } from '@angular/core';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { Board } from 'core-app/features/boards/board/board';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BehaviorSubject, firstValueFrom, Observable } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

@Injectable({ providedIn: 'root' })
export class BoardService {
  protected apiV3Service = inject(ApiV3Service);
  protected PathHelper = inject(PathHelperService);
  protected CurrentProject = inject(CurrentProjectService);
  protected halResourceService = inject(HalResourceService);
  protected I18n = inject(I18nService);

  public currentBoard$:BehaviorSubject<string|null> = new BehaviorSubject<string|null>(null);

  private loadAllPromise:Promise<Board[]>|undefined;

  private text = {
    unnamed_board: this.I18n.t('js.boards.label_unnamed_board'),
    action_board: (attr:string) => this.I18n.t('js.boards.board_type.action_by_attribute',
      { attribute: this.I18n.t(`js.boards.board_type.action_type.${attr}`) }),
    unnamed_list: this.I18n.t('js.boards.label_unnamed_list'),
  };

  /**
   * Return all boards in the current scope of the project
   *
   * @param projectIdentifier
   */
  public loadAllBoards(projectIdentifier:string|null = this.CurrentProject.identifier, force = false) {
    if (force || this.loadAllPromise === undefined) {
      this.loadAllPromise = firstValueFrom(
        this
          .apiV3Service
          .boards
          .allInScope(projectIdentifier!),
      );
    }

    return this.loadAllPromise;
  }

  /**
   * Check whether the current user can manage board-type grids.
   */
  public canManage(board:Board):boolean {
    return !!board.grid.$links.delete;
  }

  /**
   * Save the changes to the board
   */
  public save(board:Board):Observable<Board> {
    this.reorderWidgets(board);
    return this
      .apiV3Service
      .boards
      .id(board)
      .save(board);
  }

  public delete(board:Board):Promise<unknown> {
    return firstValueFrom(
      this
        .apiV3Service
        .boards
        .id(board)
        .delete(),
    );
  }

  /**
   * Reorders the widgets to correspond to the available columns
   * @param board
   */
  private reorderWidgets(board:Board) {
    board.grid.columnCount = Math.max(board.grid.widgets.length, 1);
    board.grid.widgets.map((el:GridWidgetResource, index:number) => {
      el.startColumn = index + 1;
      el.endColumn = index + 2;
      return el;
    });
  }
}
