import {Injectable} from "@angular/core";
import {StateCacheService} from "core-components/states/state-cache.service";
import {BoardResource} from "core-app/modules/boards/board/board-resource";
import {multiInput, MultiInputState} from "reactivestates";
import {BoardService} from "core-app/modules/boards/board/board-dm.service";

@Injectable()
export class BoardCacheService extends StateCacheService<BoardResource> {

  protected _state = multiInput<BoardResource>();

  constructor(protected BoardDm:BoardService) {
    super();
  }

  public create(name:string = 'New board'):Promise<BoardResource> {
    return this.BoardsList
      .create()
      .then(query => {
        const id:number = _.max(this.boards.map(b => b.id)) || 0;
        const board = new BoardResource(id + 1, name, [query]);
        this.boards.push(board);

        return board;
      });
  }

  update(board:BoardResource) {
    _.remove(this.boards, b => b.id === board.id);
    this.boards.push(board);
  }

  protected load(id:string):Promise<BoardResource> {
    return this.BoardDm
      .one(parseInt(id))
      .then((board) => {
        this.updateValue(id, board);
        return board;
      });

  }

  protected loadAll(ids:string[]):Promise<undefined> {
    return this.BoardDm
      .allInScope()
      .then((boards) => {
         boards.forEach(b => this.updateValue(b.id, b as BoardResource));
         return undefined;
    });
  }

  protected get multiState():MultiInputState<BoardResource> {
    return this._state;
  }
}
