import {Component} from "@angular/core";
import {Observable} from "rxjs";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {Board} from "core-app/modules/boards/board/board";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {tap} from "rxjs/operators";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

@Component({
  selector: 'boards-menu',
  templateUrl: './boards-menu.component.html'
})

export class BoardsMenuComponent {

  public boards$:Observable<Board[]> = this.Boards.allInScope()
    .pipe(
      tap(boards => {
        boards.forEach(b => this.BoardCache.update(b));
      })
    );

  constructor(private readonly Boards:BoardService,
              private readonly BoardCache:BoardCacheService) {
  }
}
DynamicBootstrapper.register({selector: 'boards-menu', cls: BoardsMenuComponent});
