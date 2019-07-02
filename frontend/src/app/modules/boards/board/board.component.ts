import {
  Component,
  ElementRef,
  Injector,
  OnDestroy,
  OnInit,
  QueryList,
  ViewChild,
  ViewChildren,
  ViewEncapsulation
} from "@angular/core";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {Board} from "core-app/modules/boards/board/board";
import {componentDestroyed, untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {StateService} from "@uirouter/core";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {CdkDragDrop, moveItemInArray} from "@angular/cdk/drag-drop";
import {BoardListComponent} from "core-app/modules/boards/board/board-list/board-list.component";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {AddListModalComponent} from "core-app/modules/boards/board/add-list-modal/add-list-modal.component";
import {BannersService} from "core-app/modules/common/enterprise/banners.service";
import {ApiV3Filter} from "core-components/api/api-v3/api-v3-filter-builder";
import {RequestSwitchmap} from "core-app/helpers/rxjs/request-switchmap";
import {from, Subscription} from "rxjs";
import {BoardFilterComponent} from "core-app/modules/boards/board/board-filter/board-filter.component";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {DragAndDropService} from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import {QueryUpdatedService} from "core-app/modules/boards/board/query-updated/query-updated.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";

@Component({
  selector: 'board',
  templateUrl: './board.component.html',
  styleUrls: ['./board.component.sass'],
  // Necessary to let the board span the complete height of the screen
  encapsulation: ViewEncapsulation.None,
  providers: [
    DragAndDropService,
  ]
})
export class BoardComponent implements OnInit, OnDestroy {

  /** Reference all query children to extract current actions */
  @ViewChildren(BoardListComponent) lists:QueryList<BoardListComponent>;

  public _container:HTMLElement;

  /** Container reference */
  @ViewChild('container', { static: false })
  set container(v:ElementRef|undefined) {
    // ViewChild reference may be undefined initially
    // due to ngIf
    if (v !== undefined) {
      if (this._container === undefined) {
        this.Drag.addScrollContainer(v.nativeElement);
      }
      setTimeout(() => this._container = v.nativeElement);
    }
  }

  /** Reference to the filter component */
  @ViewChild(BoardFilterComponent, { static: false })
  set content(v:BoardFilterComponent|undefined) {
    // ViewChild reference may be undefined initially
    // due to ngIf
    if (v !== undefined) {
      setTimeout(() => v.doInitialize());
    }
  }

  /** Board observable */
  public board:Board;

  /** Whether this is a new board just created */
  public isNew:boolean = !!this.state.params.isNew;

  /** Whether we're in flight of updating the board */
  public inFlight = false;

  /** Board filter */
  public filters:ApiV3Filter[];

  public text = {
    button_more: this.I18n.t('js.button_more'),
    delete: this.I18n.t('js.button_delete'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
    deleteSuccessful: this.I18n.t('js.notice_successful_delete'),
    updateSuccessful: this.I18n.t('js.notice_successful_update'),
    unnamedBoard: this.I18n.t('js.boards.label_unnamed_board'),
    loadingError: 'No such board found',
    addList: this.I18n.t('js.boards.add_list'),
    upsaleBoards: this.I18n.t('js.boards.upsale.boards'),
    upsaleCheckOutLink: this.I18n.t('js.boards.upsale.check_out_link'),
    unnamed_list: this.I18n.t('js.boards.label_unnamed_list'),
  };

  // We remember when we want to update the board
  private boardSaver = new RequestSwitchmap(
    (board:Board) => {
      this.inFlight = true;
      const promise = this.Boards
        .save(board)
        .then(board => {
          this.inFlight = false;
          return board;
        })
        .catch((error) => {
          this.inFlight = false;
          throw error;
        });

      return from(promise);
    }
  );

  trackByQueryId = (index:number, widget:GridWidgetResource) => widget.options.query_id;

  constructor(public readonly state:StateService,
              private readonly I18n:I18nService,
              private readonly notifications:NotificationsService,
              private readonly wpNotifications:WorkPackageNotificationService,
              private readonly BoardList:BoardListsService,
              private readonly opModalService:OpModalService,
              private readonly injector:Injector,
              private readonly BoardCache:BoardCacheService,
              private readonly Boards:BoardService,
              private readonly Banner:BannersService,
              private readonly Drag:DragAndDropService,
              private readonly QueryUpdated:QueryUpdatedService) {
  }

  goBack() {
    this.state.go('^');
  }

  ngOnInit():void {
    const id:string = this.state.params.board_id.toString();

    // Ensure board is being loaded
    this.Boards.loadAllBoards();

    this.boardSaver
      .observe(componentDestroyed(this))
      .subscribe(
        (board:Board) => {
          this.BoardCache.update(board);
          this.notifications.addSuccess(this.text.updateSuccessful);
        },
        (error:unknown) => this.wpNotifications.handleRawError(error)
      );

    this.BoardCache
      .observe(id)
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe(board => {
        this.board = board;
        let queryProps = this.state.params.query_props;
        this.filters = queryProps ? JSON.parse(queryProps) : this.board.filters;

        this.setupQueryUpdatedMonitoring();
      });
  }

  ngOnDestroy():void {
    // Nothing to do.
  }

  saveWithNameAndFilters(board:Board, newName:string) {
    board.name = newName;
    board.filters = this.filters;

    let params = { isNew: false, query_props: null };
    this.state.go('.', params, {custom: {notify: false}});

    this.saveBoard(board);
  }

  showError(text = this.text.loadingError) {
    this.notifications.addError(text);
  }

  saveBoard(board:Board):void {
    this.boardSaver.request(board);
  }

  addList(board:Board):any {
    if (board.isFree) {
      return this.BoardList
        .addFreeQuery(board, { name: this.text.unnamed_list})
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
    this.saveBoard(board);
  }

  removeList(board:Board, query:GridWidgetResource) {
    board.removeQuery(query);
    this.saveBoard(board);
  }

  public showBoardListView() {
    return !this.Banner.eeShowBanners;
  }

  public opReferrer(board:Board) {
    return board.isFree ? 'boards#free' : 'boards#status';
  }

  public updateFilters(filters:ApiV3Filter[]) {
    this.filters = filters;
  }

  private currentQueryUpdatedMonitoring:Subscription;

  private setupQueryUpdatedMonitoring() {
    if (this.currentQueryUpdatedMonitoring) {
      this.currentQueryUpdatedMonitoring.unsubscribe();
    }

    this.currentQueryUpdatedMonitoring = this
                                         .QueryUpdated
                                         .monitor(this.board.queries.map((widget) => widget.options.query_id as string))
                                         .pipe(
                                           untilComponentDestroyed(this)
                                         )
                                         .subscribe((collection) => this.requestRefreshOfUpdatedLists(collection.elements));
  }

  private requestRefreshOfUpdatedLists(queries:QueryResource[]) {
    queries.forEach((query) => {
      this
        .lists
        .filter((listComponent) => {
          const id = query.id!.toString();
          const listId = (listComponent.resource.options.query_id as string|number).toString() ;

          return id === listId;
        })
        .forEach((listComponent) => listComponent.refreshQueryUnlessCaused(false));
    });
  }
}
