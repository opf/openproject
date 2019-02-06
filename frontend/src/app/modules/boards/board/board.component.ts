import {Component, OnDestroy, OnInit} from "@angular/core";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {from, Observable, Subject} from "rxjs";
import {debounceTime, distinctUntilChanged, filter, tap, withLatestFrom} from "rxjs/operators";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {Board} from "core-app/modules/boards/board/board";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {StateService} from "@uirouter/core";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";

@Component({
  selector: 'board',
  templateUrl: './board.component.html',
  styleUrls: ['./board.component.sass'],
  providers: [
    DragAndDropService,
  ]
})
export class BoardComponent implements OnInit, OnDestroy {

  // We only support 4 columns for now while the grid does not autoscale
  readonly maxCount = 4;

  /** Rename events */
  public rename$ = new Subject<string>();

  /** Board observable */
  public board$:Observable<Board|undefined>;

  public text = {
    delete: this.I18n.t('js.button_delete'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
    deleteSuccessful: this.I18n.t('js.notice_successful_delete'),
    unnamedBoard: this.I18n.t('js.boards.label_unnamed_board'),
    loadingError: 'No such board found',
    addList: 'Add list'
  };

  useCardView = false;
  trackByQueryId = (index:number, widget:GridWidgetResource) => widget.options.query_id;

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

    this.rename$
      .pipe(
        untilComponentDestroyed(this),
        debounceTime(1000),
        distinctUntilChanged(),
        withLatestFrom(this.board$),
        filter(([, board]) => board !== undefined)
      )
      .subscribe(([newName, board]) => {
        let b = board as Board;

        b.name = newName;
        this.Boards
          .save(b)
          .then(board => this.BoardCache.update(board));
      });
  }

  ngOnDestroy():void {
    // Nothing to do.
  }

  showError(text = this.text.loadingError) {
    this.notifications.addError(text);
  }

  addList(board:Board) {
    this.BoardList
      .addQuery(board)
      .then(board => this.Boards.save(board))
      .then(saved => {
        this.BoardCache.update(saved);
      })
      .catch(error => {
        this.notifications.addError(error);
      });
  }

  destroyBoard(board:Board) {
    if (!window.confirm(this.text.areYouSure)) {
      return;
    }

    this.Boards
      .delete(board)
      .then(() => {
        this.BoardCache.clearSome(board.id);
        this.goBack();
        this.notifications.addSuccess(this.text.deleteSuccessful);
      })
      .catch((error) => this.showError(error));
  }
}
