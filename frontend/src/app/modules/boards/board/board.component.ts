import {Component, OnDestroy, OnInit} from "@angular/core";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
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
import {CdkDragDrop, moveItemInArray} from "@angular/cdk/drag-drop";

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

  /** Board observable */
  public board:Board;

  /** Whether this is a new board just created */
  public isNew:boolean = !!this.state.params.isNew;

  /** Whether we're in flight of updating the board */
  public inFlight = false;


  public text = {
    button_more: this.I18n.t('js.button_more'),
    delete: this.I18n.t('js.button_delete'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
    deleteSuccessful: this.I18n.t('js.notice_successful_delete'),
    updateSuccessful: this.I18n.t('js.notice_successful_update'),
    unnamedBoard: this.I18n.t('js.boards.label_unnamed_board'),
    loadingError: 'No such board found',
    addList: 'Add list'
  };

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
    const id:string = this.state.params.board_id.toString();

    this.BoardCache
      .requireAndStream(id)
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe(board => this.board = board);
  }

  ngOnDestroy():void {
    // Nothing to do.
  }

  renameBoard(board:Board, newName:string) {
    this.inFlight = true;

    board.name = newName;
    this.Boards
      .save(board)
      .then(board => {
        this.BoardCache.update(board);
        this.notifications.addSuccess(this.text.updateSuccessful);
        this.inFlight = false;
      });
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

  moveList(board:Board, event:CdkDragDrop<GridWidgetResource[]>) {
    moveItemInArray(board.queries, event.previousIndex, event.currentIndex);
    this.Boards.save(board);
  }
}
