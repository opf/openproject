import {Component, Injector, OnDestroy, OnInit, QueryList, ViewChild, ViewChildren} from "@angular/core";
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
import {BoardListComponent} from "core-app/modules/boards/board/board-list/board-list.component";
import {BoardActionsRegistryService} from "core-app/modules/boards/board/board-actions/board-actions-registry.service";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {AddListModalComponent} from "core-app/modules/boards/board/add-list-modal/add-list-modal.component";
import {DynamicCssService} from "core-app/modules/common/dynamic-css/dynamic-css.service";
import {init} from "protractor/built/launcher";


@Component({
  selector: 'board',
  templateUrl: './board.component.html',
  styleUrls: ['./board.component.sass'],
  providers: [
    DragAndDropService,
  ]
})
export class BoardComponent implements OnInit, OnDestroy {

  /** Reference all query children to extract current actions */
  @ViewChildren(BoardListComponent) lists:QueryList<BoardListComponent>;

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
    addList: this.I18n.t('js.boards.add_list')
  };

  trackByQueryId = (index:number, widget:GridWidgetResource) => widget.options.query_id;

  constructor(private readonly state:StateService,
              private readonly I18n:I18nService,
              private readonly notifications:NotificationsService,
              private readonly BoardList:BoardListsService,
              private readonly QueryDm:QueryDmService,
              private readonly opModalService:OpModalService,
              private readonly injector:Injector,
              private readonly boardActions:BoardActionsRegistryService,
              private readonly BoardCache:BoardCacheService,
              private readonly dynamicCss:DynamicCssService,
              private readonly Boards:BoardService) {
  }

  goBack() {
    this.state.go('^');
  }

  ngOnInit():void {
    const id:string = this.state.params.board_id.toString();
    let initialized = false;

    this.BoardCache
      .requireAndStream(id)
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe(board => {
        this.board = board;

        if (board.isAction && !initialized) {
          this.dynamicCss.requireHighlighting();
          initialized = true;
        }
      });
  }

  ngOnDestroy():void {
    // Nothing to do.
  }

  renameBoard(board:Board, newName:string) {
    board.name = newName;
    return this.saveBoard(board);
  }

  showError(text = this.text.loadingError) {
    this.notifications.addError(text);
  }

  saveBoard(board:Board) {
    this.inFlight = true;
    this.Boards
      .save(board)
      .then(board => {
        this.BoardCache.update(board);
        this.notifications.addSuccess(this.text.updateSuccessful);
        this.inFlight = false;
      });
  }

  addList(board:Board):any {
    if (board.isFree) {
      return this.BoardList
        .addFreeQuery(board, { name: 'Unnamed list'})
        .then(board => this.Boards.save(board))
        .then(saved => {
          this.BoardCache.update(saved);
        })
        .catch(error => this.showError(error));
    } else {
      const queries = this.lists.map(list => list.query);
      this.opModalService.show(
        AddListModalComponent,
        this.injector,
        { board: board, queries: queries }
      );
    }
  }

  moveList(board:Board, event:CdkDragDrop<GridWidgetResource[]>) {
    moveItemInArray(board.queries, event.previousIndex, event.currentIndex);
    return this.saveBoard(board);
  }

  removeList(board:Board, query:GridWidgetResource) {
    board.removeQuery(query);
    return this.saveBoard(board);
  }
}
