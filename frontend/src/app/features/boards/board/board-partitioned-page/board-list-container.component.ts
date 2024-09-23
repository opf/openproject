import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Injector,
  OnInit,
  QueryList,
  ViewChild,
  ViewChildren,
} from '@angular/core';
import { EMPTY, Observable, Subscription } from 'rxjs';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { BoardListComponent } from 'core-app/features/boards/board/board-list/board-list.component';
import { StateService } from '@uirouter/core';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { BoardListsService } from 'core-app/features/boards/board/board-list/board-lists.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { DragAndDropService } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { QueryUpdatedService } from 'core-app/features/boards/board/query-updated/query-updated.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { Board, BoardWidgetOption } from 'core-app/features/boards/board/board';
import { CdkDragDrop, moveItemInArray } from '@angular/cdk/drag-drop';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import {
  BoardPartitionedPageComponent,
} from 'core-app/features/boards/board/board-partitioned-page/board-partitioned-page.component';
import { AddListModalComponent } from 'core-app/features/boards/board/add-list-modal/add-list-modal.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  BoardListCrossSelectionService,
} from 'core-app/features/boards/board/board-list/board-list-cross-selection.service';
import { catchError, filter, finalize, tap } from 'rxjs/operators';
import {
  BoardActionsRegistryService,
} from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import {
  WorkPackageStatesInitializationService,
} from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { enterpriseDocsUrl } from 'core-app/core/setup/globals/constants.const';

@Component({
  templateUrl: './board-list-container.component.html',
  styleUrls: ['./board-list-container.component.sass'],
  providers: [
    BoardListCrossSelectionService,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BoardListContainerComponent extends UntilDestroyedMixin implements OnInit {
  text = {
    delete: this.I18n.t('js.button_delete'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
    deleteSuccessful: this.I18n.t('js.notice_successful_delete'),
    updateSuccessful: this.I18n.t('js.notice_successful_update'),
    loadingError: 'No such board found',
    addList: this.I18n.t('js.boards.add_list'),
    unnamedList: this.I18n.t('js.boards.label_unnamed_list'),
    hiddenListWarning: this.I18n.t('js.boards.text_hidden_list_warning'),
    teaser_text: this.I18n.t('js.boards.upsale.teaser_text'),
    upgrade_to_ee_text: this.I18n.t('js.boards.upsale.upgrade'),
    more_info_link: enterpriseDocsUrl.boards,
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
      setTimeout(() => (this._container = v.nativeElement));
    }
  }

  /** Reference all query children to extract current actions */
  @ViewChildren(BoardListComponent) lists:QueryList<BoardListComponent>;

  trackByQueryId = (index:number, widget:GridWidgetResource) => widget.options.queryId;

  board$:Observable<Board>;

  boardWidgets:GridWidgetResource[] = [];

  showHiddenListWarning:boolean = false;

  needEnterpriseEdition = this.Banner.eeShowBanners;

  private currentQueryUpdatedMonitoring:Subscription;

  constructor(
readonly I18n:I18nService,
    readonly state:StateService,
    readonly toastService:ToastService,
    readonly halNotification:HalResourceNotificationService,
    readonly boardComponent:BoardPartitionedPageComponent,
    readonly BoardList:BoardListsService,
    readonly boardActionRegistry:BoardActionsRegistryService,
    readonly opModalService:OpModalService,
    readonly injector:Injector,
    readonly apiV3Service:ApiV3Service,
    readonly Boards:BoardService,
    readonly Banner:BannersService,
    readonly boardListCrossSelectionService:BoardListCrossSelectionService,
    readonly wpStatesInitialization:WorkPackageStatesInitializationService,
    readonly Drag:DragAndDropService,
    readonly apiv3Service:ApiV3Service,
    readonly QueryUpdated:QueryUpdatedService,
) {
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
        tap((board) => this.setupQueryUpdatedMonitoring(board)),
      );

    this.board$.subscribe((board) => {
      this.needEnterpriseEdition = this.Banner.eeShowBanners && !board.isFree;
    });

    this.Boards.currentBoard$.next(id);

    this.boardListCrossSelectionService
      .selections()
      .pipe(
        this.untilDestroyed(),
        filter((state) => state.focusedWorkPackage !== null),
        filter(() => this.state.includes(`${this.state.current.data.baseRoute}.details`)),
      ).subscribe((selection) => {
      // Update split screen
        this.state.go(`${this.state.current.data.baseRoute}.details`, { workPackageId: selection.focusedWorkPackage });
      });
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
        .addFreeQuery(board, { name: this.text.unnamedList })
        .then((board) => this.Boards.save(board).toPromise())
        .catch((error) => this.showError(error));
    }
    const active = this.getActionFiltersFromWidget(board);
    this.opModalService.show(
      AddListModalComponent,
      this.injector,
      { board, active },
    );
  }

  changeVisibilityOfList(board:Board, boardWidget:GridWidgetResource, visible:boolean) {
    if (!visible) {
      this.showHiddenListWarning = true;
      this.boardWidgets = this.boardWidgets.filter((widget) => widget.id !== boardWidget.id);
    }
  }

  saveBoard(board:Board):void {
    this.Boards
      .save(board)
      .pipe(
        catchError((error) => {
          this.halNotification.handleRawError(error);
          return EMPTY;
        }),
        finalize(() => {
          this.boardComponent.toolbarDisabled = false;
          this.boardComponent.cdRef.detectChanges();
        }),
      ).subscribe(() => {
        this.toastService.addSuccess(this.text.updateSuccessful);
      });
  }

  private setupQueryUpdatedMonitoring(board:Board) {
    if (this.currentQueryUpdatedMonitoring) {
      this.currentQueryUpdatedMonitoring.unsubscribe();
    }

    this.boardWidgets = board.queries;

    this.currentQueryUpdatedMonitoring = this
      .QueryUpdated
      .monitor(board.queries.map((widget) => widget.options.queryId as string))
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((collection) => this.requestRefreshOfUpdatedLists(collection.elements));
  }

  private showError(text = this.text.loadingError) {
    this.toastService.addError(text);
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
      .map((widget) => {
        const service = this.boardActionRegistry.get(board.actionAttribute!);
        const { filterName } = service;
        const idFilterName = `${filterName}_id`;
        const options = widget.options as unknown as BoardWidgetOption;
        const instance = _.find(options.filters, (f) => !!f[filterName] || !!f[idFilterName]);

        if (instance) {
          return ((instance[filterName] || instance[idFilterName])?.values[0] || null) as unknown as string|null;
        }

        return null;
      })
      .filter((value) => value !== undefined);
  }
}
