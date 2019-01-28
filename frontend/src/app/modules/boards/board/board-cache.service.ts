import {Injectable} from "@angular/core";
import {StateCacheService} from "core-components/states/state-cache.service";
import {multiInput, MultiInputState} from "reactivestates";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {Board} from "core-app/modules/boards/board/board";

@Injectable()
export class BoardCacheService extends StateCacheService<Board> {

  protected _state = multiInput<Board>();

  constructor(protected BoardDm:BoardService) {
    super();
  }

  protected load(id:string):Promise<Board> {
    return this.BoardDm
      .one(parseInt(id))
      .toPromise()
      .then((board:Board) => {
        this.updateValue(id, board);
        return board;
      });

  }

  protected loadAll(ids:string[]):Promise<undefined> {
    return this.BoardDm
      .allInScope()
      .toPromise()
      .then((boards) => {
         boards.forEach(b => this.updateValue(b.id, b));
         return undefined;
    });
  }

  protected get multiState():MultiInputState<Board> {
    return this._state;
  }

  update(board:Board) {
    this.updateValue(board.id, board);
  }
}
