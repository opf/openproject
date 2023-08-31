import { Injectable } from '@angular/core';
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
  public currentBoard$:BehaviorSubject<string|null> = new BehaviorSubject<string|null>(null);

  private loadAllPromise:Promise<Board[]>|undefined;

  private text = {
    unnamed_board: this.I18n.t('js.boards.label_unnamed_board'),
    action_board: (attr:string) => this.I18n.t('js.boards.board_type.action_by_attribute',
      { attribute: this.I18n.t(`js.boards.board_type.action_type.${attr}`) }),
    unnamed_list: this.I18n.t('js.boards.label_unnamed_list'),
  };

  constructor(
    protected apiV3Service:ApiV3Service,
    protected PathHelper:PathHelperService,
    protected CurrentProject:CurrentProjectService,
    protected halResourceService:HalResourceService,
    protected I18n:I18nService,
  ) {
  }

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
          .allInScope(projectIdentifier as string),
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
