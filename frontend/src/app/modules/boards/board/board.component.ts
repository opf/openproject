import {Component, OnDestroy, OnInit} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {StateService} from "@uirouter/core";
import {Observable} from "rxjs";
import {BoardsService} from "core-app/modules/boards/board/boards.service";
import {filter, tap} from "rxjs/operators";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

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
    // Nothing to do
  }

  addList(board:Board) {
    board.queries = [...board.queries, 5];
    this.Boards.update(board);
  }
}
