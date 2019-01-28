import {Component, OnInit} from "@angular/core";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {StateService} from "@uirouter/core";
import {from, Observable} from "rxjs";
import {tap} from "rxjs/operators";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {Board} from "core-app/modules/boards/board/board";

@Component({
  selector: 'board',
  templateUrl: './board.component.html',
  styleUrls: ['./board.component.sass'],
  providers: [
    DragAndDropService
  ]
})
export class BoardComponent implements OnInit {

  // We only support 4 columns for now while the grid does not autoscale
  readonly maxCount = 4;

  public board$:Observable<Board|undefined>;

  public text = {
    loadingError: 'No such board found',
    addList: 'Add list'
  };

  constructor(private readonly state:StateService,
              private readonly I18n:I18nService,
              private readonly notifications:NotificationsService,
              private readonly BoardList:BoardListsService,
              private readonly QueryDm:QueryDmService,
              private readonly BoardCache:BoardCacheService,
              private readonly Boards:BoardService) {
  }

  goBack() {
    this.state.go('^');
  }

  updateBoardName(board:Board, name:string) {
    board.name = name;
    this.BoardCache.update(board);
  }

  ngOnInit():void {
    const id:number = this.state.params.id;
    this.BoardCache.require(id.toString());
    this.board$ = from(this.BoardCache.observe(id.toString()))
      .pipe(
        tap(b => {
          if (b === undefined) {
            this.showError();
          }
        })
      );

  }

  showError() {
    this.notifications.addError(this.text.loadingError);
  }

  addList(board:Board) {
    this.BoardList
      .addQuery(board)
      .then(board => this.Boards.save(board))
      .then(saved => {
        this.BoardCache.update(saved);
      });
  }
}
