import {Component} from "@angular/core";
import {Observable} from "rxjs";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {Board} from "core-app/modules/boards/board/board";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {filter, tap} from "rxjs/operators";
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";

@Component({
  selector: 'boards-menu',
  templateUrl: './boards-menu.component.html'
})

export class BoardsMenuComponent {
  trackById = AngularTrackingHelpers.compareByAttribute('id');

  public boards$:Observable<Board[]> = this.BoardCache
    .observeAll()
    .pipe(
      filter(boards => !!boards && boards.length !== 0),
      tap((boards) => console.log(boards))
    );

  constructor(private readonly Boards:BoardService,
              private readonly BoardCache:BoardCacheService) {

    this.BoardCache.requireLoaded();
  }
}
DynamicBootstrapper.register({selector: 'boards-menu', cls: BoardsMenuComponent});
