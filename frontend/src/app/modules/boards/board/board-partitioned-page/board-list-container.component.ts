import { Component, ElementRef, Injector, OnInit, QueryList, ViewChild, ViewChildren } from "@angular/core";
import { forkJoin, Observable, of, Subscription } from "rxjs";
import { QueryResource } from "core-app/modules/hal/resources/query-resource";
import { BoardListComponent } from "core-app/modules/boards/board/board-list/board-list.component";
import { StateService } from "@uirouter/core";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { HalResourceNotificationService } from "core-app/modules/hal/services/hal-resource-notification.service";
import { BoardListsService } from "core-app/modules/boards/board/board-list/board-lists.service";
import { OpModalService } from "core-app/modules/modal/modal.service";
import { BoardService } from "core-app/modules/boards/board/board.service";
import { BannersService } from "core-app/modules/common/enterprise/banners.service";
import { DragAndDropService } from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import { QueryUpdatedService } from "core-app/modules/boards/board/query-updated/query-updated.service";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { Board, BoardWidgetOption } from "core-app/modules/boards/board/board";
import { CdkDragDrop, moveItemInArray } from "@angular/cdk/drag-drop";
import { GridWidgetResource } from "core-app/modules/hal/resources/grid-widget-resource";
import { BoardPartitionedPageComponent } from "core-app/modules/boards/board/board-partitioned-page/board-partitioned-page.component";
import { AddListModalComponent } from "core-app/modules/boards/board/add-list-modal/add-list-modal.component";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { BoardListCrossSelectionService } from "core-app/modules/boards/board/board-list/board-list-cross-selection.service";
import { catchError, filter, map, switchMap, tap } from "rxjs/operators";
import { BoardActionsRegistryService } from "core-app/modules/boards/board/board-actions/board-actions-registry.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { WorkPackageStatesInitializationService } from 'core-app/components/wp-list/wp-states-initialization.service';

@Component({
  templateUrl: './board-list-container.component.html',
  styleUrls: ['./board-list-container.component.sass'],
  providers: [
    BoardListCrossSelectionService
  ]
})
export class BoardListContainerComponent extends UntilDestroyedMixin implements OnInit {

  text = {
    button_more: this.I18n.t('js.button_more'),
    delete: this.I18n.t('js.button_delete'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
    deleteSuccessful: this.I18n.t('js.notice_successful_delete'),
    updateSuccessful: this.I18n.t('js.notice_successful_update'),
    loadingError: 'No such board found',
    addList: this.I18n.t('js.boards.add_list'),
    upsaleBoards: this.I18n.t('js.boards.upsale.teaser_text'),
    upsaleCheckOutLink: this.I18n.t('js.work_packages.table_configuration.upsale.check_out_link'),
    unnamed_list: this.I18n.t('js.boards.label_unnamed_list'),
  };


  /** Container reference */
  public _container:HTMLElement;
  @ViewChild('container')
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

  /** Reference all query children to extract current actions */
  @ViewChildren(BoardListComponent) lists:QueryList<BoardListComponent>;

  trackByQueryId = (index:number, widget:GridWidgetResource) => widget.options.queryId;

  board$:Observable<Board>;
  boardWidgets:GridWidgetResource[] = [];

  private currentQueryUpdatedMonitoring:Subscription;

  constructor(readonly I18n:I18nService,
              readonly state:StateService,
              readonly notifications:NotificationsService,
              readonly halNotification:HalResourceNotificationService,
              readonly boardComponent:BoardPartitionedPageComponent,
              readonly BoardList:BoardListsService,
              readonly boardActionRegistry:BoardActionsRegistryService,
              readonly opModalService:OpModalService,
              readonly injector:Injector,
              readonly apiV3Service:APIV3Service,
              readonly Boards:BoardService,
              readonly Banner:BannersService,
              readonly boardListCrossSelectionService:BoardListCrossSelectionService,
              readonly wpStatesInitialization:WorkPackageStatesInitializationService,
              readonly Drag:DragAndDropService,
              readonly apiv3Service:APIV3Service,
              readonly QueryUpdated:QueryUpdatedService) {
    super();
  }

  ngOnInit():void {
    const id:string = this.state.params.board_id.toString();
    this.board$ = this
      .apiV3Service
      .boards
      .id(id)
      .requireAndStream()
      .pipe(
        this.setAllowedBoardWidgets,
        tap(board => this.setupQueryUpdatedMonitoring(board))
      );

    this.Boards.currentBoard$.next(id);

    this.boardListCrossSelectionService
      .selections()
      .pipe(
        this.untilDestroyed(),
        filter((state) => state.focusedWorkPackage !== null),
        filter(() => this.state.includes(this.state.current.data.baseRoute + '.details'))
      ).subscribe(selection => {
      // Update split screen
        this.state.go(this.state.current.data.baseRoute + '.details', { workPackageId: selection.focusedWorkPackage });
      });
  }

  setAllowedBoardWidgets = (boardObservable:Observable<Board>) => {
    // The grid config could have widgets that the user is not allowed to
    // see, so we filter out those that rise an access error.
    return boardObservable
      .pipe(
        switchMap(
          board => this.getAllowedBoardWidgets(board).pipe(map(allowedBoardWidgets => ({ board, allowedBoardWidgets }))),
        ),
        map(result => {
          this.boardWidgets = result.allowedBoardWidgets;

          return result.board;
        })
      );
  };

  getAllowedBoardWidgets(board:Board) {
    if (board.queries?.length) {
      const queryRequests$ = board.queries.map(query => this.apiv3Service.queries
        .find({ filters: JSON.stringify(query.options.filters), pageSize: 0 }, query.options.queryId as string)
        .pipe(
          map(() => query),
          catchError(error => {
            const userIsNotAllowedToSeeSubprojectError = 'urn:openproject-org:api:v3:errors:InvalidQuery';
            const result = error.errorIdentifier ===  userIsNotAllowedToSeeSubprojectError ? null : query;

            return of(result);
          })
        )
      );

      return forkJoin([...queryRequests$])
        .pipe(map(boardWidgets => boardWidgets.filter(boardWidget => !!boardWidget) as GridWidgetResource[]));
    } else {
      return of([]);
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

  addList(board:Board):any {
    if (board.isFree) {
      return this.BoardList
        .addFreeQuery(board, { name: this.text.unnamed_list })
        .then(board => this.Boards.save(board).toPromise())
        .catch(error => this.showError(error));
    } else {
      const active = this.getActionFiltersFromWidget(board);
      this.opModalService.show(
        AddListModalComponent,
        this.injector,
        { board: board, active: active }
      );
    }
  }

  showBoardListView() {
    return !this.Banner.eeShowBanners;
  }

  opReferrer(board:Board) {
    return board.isFree ? 'boards#free' : 'boards#status';
  }

  saveBoard(board:Board):void {
    this.boardComponent.boardSaver.request(board);
  }

  private setupQueryUpdatedMonitoring(board:Board) {
    if (this.currentQueryUpdatedMonitoring) {
      this.currentQueryUpdatedMonitoring.unsubscribe();
    }

    this.currentQueryUpdatedMonitoring = this
      .QueryUpdated
      .monitor(board.queries.map((widget) => widget.options.queryId as string))
      .pipe(
        this.untilDestroyed()
      )
      .subscribe((collection) => this.requestRefreshOfUpdatedLists(collection.elements));
  }

  private showError(text = this.text.loadingError) {
    this.notifications.addError(text);
  }

  private requestRefreshOfUpdatedLists(queries:QueryResource[]) {
    queries.forEach((query) => {
      this
        .lists
        .filter((listComponent) => {
          const id = query.id!.toString();
          const listId = (listComponent.resource.options.queryId as string|number).toString();

          return id === listId;
        })
        .forEach((listComponent) => listComponent.refreshQueryUnlessCaused(query, false));
    });
  }

  /**
   * Returns the current filter values for an action board.
   * By extracting them from the widget options, we can avoid waiting for the queries
   * to be loaded for each list
   *
   * @param board
   */
  private getActionFiltersFromWidget(board:Board):(string|null)[] {
    return board.grid.widgets
      .map(widget => {
        const service = this.boardActionRegistry.get(board.actionAttribute!);
        const filterName = service.filterName;
        const options:BoardWidgetOption = widget.options as any;
        const filter = _.find(options.filters, (filter) => !!filter[filterName]);

        if (filter) {
          return (filter[filterName].values[0] || null) as any;
        }
      })
      .filter(value => value !== undefined);
  }

}
