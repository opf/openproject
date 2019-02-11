import {Component} from "@angular/core";
import {Observable} from "rxjs";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {Board} from "core-app/modules/boards/board/board";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";

@Component({
  selector: 'boards-menu',
  templateUrl: './boards-menu.component.html'
})

export class BoardsMenuComponent {
  trackById = AngularTrackingHelpers.compareByAttribute('id');

  public boards$:Observable<Board[]> = this.boardCache.observeAll();

  constructor(private readonly boardService:BoardService,
              private readonly boardCache:BoardCacheService) {

    this.boardService.loadAllBoards();
  }
}
DynamicBootstrapper.register({selector: 'boards-menu', cls: BoardsMenuComponent});
