import {Component, OnDestroy, OnInit} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {StateService} from "@uirouter/core";
import {Observable} from "rxjs";
import {BoardsService} from "core-app/modules/boards/board/boards.service";
import {filter, take, tap} from "rxjs/operators";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";

@Component({
  selector: 'board',
  templateUrl: './board.component.html',
  styleUrls: ['./board.component.sass'],
  providers: [
    DragAndDropService
  ]
})
export class BoardComponent implements OnInit, OnDestroy {

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
              private readonly Boards:BoardsService) {
  }

  goBack() {
    this.state.go('^');
  }

  updateBoardName(board:Board, name:string) {
    board.name = name;
    this.Boards.update(board);
  }

  ngOnInit():void {
    const id = this.state.params.id;
    this.board$ = this.Boards
      .load(id)
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

  ngOnDestroy():void {
    this.Boards
      .load(this.state.params.id)
      .pipe(
        filter(b => b !== undefined),
        take(1)
      )
      .subscribe((board:Board) => {
        board.queries.forEach((el) => {
          if (el instanceof HalResource) {
            this.QueryDm.delete(el);
          }
        });
      });
  }

  addList(board:Board) {
    this.BoardList
      .create()
      .then(query => {
        board.queries = [...board.queries, query];
        this.Boards.update(board);
      });
  }
}
