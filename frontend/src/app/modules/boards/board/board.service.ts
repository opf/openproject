import {Injectable} from "@angular/core";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {Board} from "core-app/modules/boards/board/board";
import {BoardDmService} from "core-app/modules/boards/board/board-dm.service";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";

@Injectable()
export class BoardService {

  private loadAllPromise:Promise<Board[]>|undefined;

  constructor(protected boardDm:BoardDmService,
              protected PathHelper:PathHelperService,
              protected CurrentProject:CurrentProjectService,
              protected halResourceService:HalResourceService,
              protected boardCache:BoardCacheService,
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

    return this.loadAllPromise = this.boardDm
      .allInScope()
      .toPromise()
      .then((boards) => {
        boards.forEach(b => this.boardCache.update(b));
        return boards;
      });
  }

  /**
   * Save the changes to the board
   */
  public save(board:Board) {
    this.reorderWidgets(board);
    return this.boardDm.save(board)
      .then(board => {
        this.boardCache.update(board);
        return board;
      });
  }

  /**
   * Create a new board
   * @param name
   */
  public async create(name:string = 'New board'):Promise<Board> {
    const board = await this.boardDm.create(name);

    await this.boardsList.addQuery(board);
    await this.save(board);

    return board;
  }

  public delete(board:Board):Promise<void> {
    return this.boardDm
      .delete(board)
      .then(() => this.boardCache.clearSome(board.id));
  }

  /**
   * Reorders the widgets to correspond to the available columns
   * @param board
   */
  private reorderWidgets(board:Board) {
    board.grid.widgets.map((el:GridWidgetResource, index:number) => {
      el.startColumn = index + 1;
      el.endColumn = index + 2;
      return el;
    });
  }
}
