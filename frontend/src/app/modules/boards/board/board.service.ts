import { Injectable } from "@angular/core";
import { BoardListsService } from "core-app/modules/boards/board/board-list/board-lists.service";
import { HalResourceService } from "core-app/modules/hal/services/hal-resource.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { CurrentProjectService } from "core-components/projects/current-project.service";
import { Board, BoardType } from "core-app/modules/boards/board/board";
import { GridWidgetResource } from "core-app/modules/hal/resources/grid-widget-resource";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { BoardActionsRegistryService } from "core-app/modules/boards/board/board-actions/board-actions-registry.service";
import { BehaviorSubject, Observable } from "rxjs";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

export interface CreateBoardParams {
  type:BoardType;
  boardName?:string;
  attribute?:string;
}

@Injectable({ providedIn: 'root' })
export class BoardService {

  public currentBoard$:BehaviorSubject<string|null> = new BehaviorSubject<string|null>(null);

  private loadAllPromise:Promise<Board[]>|undefined;

  private text = {
    unnamed_board: this.I18n.t('js.boards.label_unnamed_board'),
    action_board: (attr:string) => this.I18n.t('js.boards.board_type.action_by_attribute',
      { attribute: this.I18n.t('js.boards.board_type.action_type.' + attr) }),
    unnamed_list: this.I18n.t('js.boards.label_unnamed_list'),
  };

  constructor(protected apiV3Service:APIV3Service,
              protected PathHelper:PathHelperService,
              protected CurrentProject:CurrentProjectService,
              protected halResourceService:HalResourceService,
              protected boardActions:BoardActionsRegistryService,
              protected I18n:I18nService,
              protected boardsList:BoardListsService) {
  }

  /**
   * Return all boards in the current scope of the project
   *
   * @param projectIdentifier
   */
  public loadAllBoards(projectIdentifier:string|null = this.CurrentProject.identifier, force = false) {
    if (!(force || this.loadAllPromise === undefined)) {
      return this.loadAllPromise;
    }

    return this.loadAllPromise = this
      .apiV3Service
      .boards
      .allInScope(projectIdentifier!)
      .toPromise();
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

  /**
   * Create a new board
   * @param name
   */
  public async create(params:CreateBoardParams):Promise<Board> {
    const board = await this
      .apiV3Service
      .boards
      .create(params.type, this.boardName(params), this.CurrentProject.identifier!, params.attribute).toPromise();

    if (params.type === 'free') {
      await this.boardsList.addFreeQuery(board, { name: this.text.unnamed_list });
    } else {
      await this.boardActions.get(params.attribute!).addInitialColumnsForAction(board);
    }

    await this.save(board).toPromise();

    return board;
  }

  public delete(board:Board):Promise<unknown> {
    return this
      .apiV3Service
      .boards
      .id(board)
      .delete()
      .toPromise();
  }

  /**
   * Build a default board name
   */
  private boardName(params:CreateBoardParams) {
    if (params.boardName) {
      return params.boardName;
    }

    if (params.type === "action") {
      return this.text.action_board(params.attribute!);
    }

    return this.text.unnamed_board;
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
