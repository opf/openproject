import {Component} from "@angular/core";
import {Observable} from "rxjs";
import {StateService} from "@uirouter/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {Board} from "core-app/modules/boards/board/board";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {tap} from "rxjs/operators";

@Component({
  selector: 'boards-module',
  templateUrl: './boards-module.component.html',
  styleUrls: ['./boards-module.component.sass'],
  providers: [
    BoardCacheService
  ]
})
export class BoardsModuleComponent {

  public text = {
    create: this.I18n.t('js.relation_buttons.create_new')
  };

  public boards$:Observable<Board[]> = this.Boards.allInScope()
    .pipe(
      tap(boards => {
        boards.forEach(b => this.BoardCache.update(b));
      })
    );

  constructor(private readonly Boards:BoardService,
              private readonly BoardCache:BoardCacheService,
              private readonly I18n:I18nService,
              private readonly state:StateService) {
  }

  newBoard() {
    this.Boards
      .create()
      .then((board) => {
        this.state.go('boards.show', { id: board.id });
      });
  }
}
