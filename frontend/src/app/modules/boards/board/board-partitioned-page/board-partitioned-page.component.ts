import {ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector} from "@angular/core";
import {
  DynamicComponentDefinition,
  ToolbarButtonComponentDefinition,
  ViewPartitionState
} from "core-app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component";
import {StateService, TransitionService} from "@uirouter/core";
import {BoardFilterComponent} from "core-app/modules/boards/board/board-filter/board-filter.component";
import {Board} from "core-app/modules/boards/board/board";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {DragAndDropService} from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import {WorkPackageFilterButtonComponent} from "core-components/wp-buttons/wp-filter-button/wp-filter-button.component";
import {ZenModeButtonComponent} from "core-components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component";
import {BoardsMenuButtonComponent} from "core-app/modules/boards/board/toolbar-menu/boards-menu-button.component";
import {RequestSwitchmap} from "core-app/helpers/rxjs/request-switchmap";
import {from} from "rxjs";
import {componentDestroyed} from "@w11k/ngx-componentdestroyed";
import {take} from "rxjs/operators";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {Ng2StateDeclaration} from "@uirouter/angular";
import {BoardFiltersService} from "core-app/modules/boards/board/board-filter/board-filters.service";
import {CardViewHandlerRegistry} from "core-components/wp-card-view/event-handler/card-view-handler-registry";

export function boardCardViewHandlerFactory(injector:Injector) {
  return new CardViewHandlerRegistry(injector);
}

@Component({
  templateUrl: '/app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    '/app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass',
    './board-partitioned-page.component.sass'
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    DragAndDropService,
    BoardFiltersService,
  ]
})
export class BoardPartitionedPageComponent extends UntilDestroyedMixin {

  text = {
    button_more: this.I18n.t('js.button_more'),
    delete: this.I18n.t('js.button_delete'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
    deleteSuccessful: this.I18n.t('js.notice_successful_delete'),
    updateSuccessful: this.I18n.t('js.notice_successful_update'),
    unnamedBoard: this.I18n.t('js.boards.label_unnamed_board'),
    loadingError: 'No such board found',
    addList: this.I18n.t('js.boards.add_list'),
    upsaleBoards: this.I18n.t('js.boards.upsale.teaser_text'),
    upsaleCheckOutLink: this.I18n.t('js.work_packages.table_configuration.upsale.check_out_link'),
    unnamed_list: this.I18n.t('js.boards.label_unnamed_list'),
  };

  /** Board observable */
  board$ = this.BoardCache.observe(this.state.params.board_id.toString());

  /** Whether this is a new board just created */
  isNew:boolean = !!this.state.params.isNew;

  /** Whether the board is editable */
  editable:boolean;

  /** Go back to boards using back-button */
  backButtonCallback = () => this.state.go('boards');

  /** Current query title to render */
  selectedTitle?:string;
  currentQuery:QueryResource|undefined;

  /** Whether we're saving the board */
  toolbarDisabled:boolean = false;

  /** Do we currently have query props ? */
  showToolbarSaveButton:boolean;

  /** Listener callbacks */
  removeTransitionSubscription:Function;

  showToolbar = true;

  /** Whether filtering is allowed */
  filterAllowed:boolean = true;

  /** We need to pass the correct partition state to the view to manage the grid */
  currentPartition:ViewPartitionState = '-split';

  /** We need to apply our own board filter component */
  /** Which filter container component to mount */
  filterContainerDefinition:DynamicComponentDefinition = {
    component: BoardFilterComponent,
    inputs: {
      board$: this.board$
    },
  };

  // We remember when we want to update the board
  boardSaver = new RequestSwitchmap(
    (board:Board) => {
      this.toolbarDisabled = true;
      const promise = this.Boards
        .save(board)
        .then(board => {
          this.toolbarDisabled = false;
          return board;
        })
        .catch((error) => {
          this.toolbarDisabled = false;
          throw error;
        });

      return from(promise);
    }
  );

  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: WorkPackageFilterButtonComponent,
      containerClasses: 'hidden-for-mobile'
    },
    {
      component: ZenModeButtonComponent,
      containerClasses: 'hidden-for-mobile'
    },
    {
      component: BoardsMenuButtonComponent,
      containerClasses: 'hidden-for-mobile',
      show: () => this.editable,
      inputs: {
        board$: this.board$
      }
    }
  ];

  constructor(readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef,
              readonly $transitions:TransitionService,
              readonly state:StateService,
              readonly notifications:NotificationsService,
              readonly halNotification:HalResourceNotificationService,
              readonly injector:Injector,
              readonly BoardCache:BoardCacheService,
              readonly boardFilters:BoardFiltersService,
              readonly Boards:BoardService) {
    super();
  }

  ngOnInit():void {
    // Ensure board is being loaded
    this.Boards.loadAllBoards();

    this.boardSaver
      .observe(componentDestroyed(this))
      .subscribe(
        (board:Board) => {
          this.BoardCache.update(board);
          this.notifications.addSuccess(this.text.updateSuccessful);
        },
        (error:unknown) => this.halNotification.handleRawError(error)
      );

    this.removeTransitionSubscription = this.$transitions.onSuccess({}, (transition):any => {
      const toState = transition.to();
      const params = transition.params('to');

      this.showToolbarSaveButton = !!params.query_props
      this.setPartition(toState);
      this.cdRef.detectChanges();
    });

    this.board$
      .pipe(
        this.untilDestroyed()
      )
      .subscribe(board => {
        let queryProps = this.state.params.query_props;
        this.editable = board.editable;
        this.selectedTitle = board.name;
        this.boardFilters.filters.putValue(queryProps ? JSON.parse(queryProps) : board.filters);
        this.cdRef.detectChanges();
      });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.removeTransitionSubscription();
  }

  changeChangesFromTitle(newName:string) {
    this.board$
      .pipe(take(1))
      .subscribe(board => {
        board.name = newName;
        board.filters = this.boardFilters.current;

        let params = { isNew: false, query_props: null };
        this.state.go('.', params, { custom: { notify: false } });

        this.boardSaver.request(board);
      });
  }

  updateTitleName(val:string) {
    this.changeChangesFromTitle(val);
  }

  /** Whether the title can be edited */
  get titleEditingEnabled():boolean {
    return this.editable;
  }

  /**
   * We need to set the current partition to the grid to ensure
   * either side gets expanded to full width if we're not in '-split' mode.
   *
   * @param state The current or entering state
   */
  protected setPartition(state:Ng2StateDeclaration) {
    this.currentPartition = (state.data && state.data.partition) ? state.data.partition : '-split';
  }
}
