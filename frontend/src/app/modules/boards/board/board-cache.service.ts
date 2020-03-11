import {Injectable} from "@angular/core";
import {StateCacheService} from "core-components/states/state-cache.service";
import {multiInput, MultiInputState} from "reactivestates";
import {Board} from "core-app/modules/boards/board/board";
import {BoardDmService} from "core-app/modules/boards/board/board-dm.service";

@Injectable({ providedIn: 'root' })
export class BoardCacheService extends StateCacheService<Board> {

  protected _state = multiInput<Board>();

  constructor(protected boardDm:BoardDmService) {
    super();
  }

  protected load(id:string):Promise<Board> {
    return this.boardDm
      .one(parseInt(id))
      .toPromise()
      .then((board:Board) => {
        this.updateValue(id, board);
        return board;
      });

  }

  protected loadAll(ids:string[] = []):Promise<undefined> {
    return Promise
      .all(ids.map(id => this.load(id)))
      .then(() => undefined);
  }

  protected get multiState():MultiInputState<Board> {
    return this._state;
  }

  update(board:Board) {
    this.updateValue(board.id!, board);
  }
}
