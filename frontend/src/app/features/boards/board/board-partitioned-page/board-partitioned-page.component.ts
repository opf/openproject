import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Injector,
} from '@angular/core';
import {
  DynamicComponentDefinition,
  ToolbarButtonComponentDefinition,
  ViewPartitionState,
} from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component';
import { StateService, TransitionService } from '@uirouter/core';
import { BoardFilterComponent } from 'core-app/features/boards/board/board-filter/board-filter.component';
import { Board } from 'core-app/features/boards/board/board';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { DragAndDropService } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { WorkPackageFilterButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-filter-button/wp-filter-button.component';
import { ZenModeButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import { BoardsMenuButtonComponent } from 'core-app/features/boards/board/toolbar-menu/boards-menu-button.component';
import { RequestSwitchmap } from 'core-app/shared/helpers/rxjs/request-switchmap';
import { componentDestroyed } from '@w11k/ngx-componentdestroyed';
import { finalize, take } from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { Ng2StateDeclaration } from '@uirouter/angular';
import { BoardFiltersService } from 'core-app/features/boards/board/board-filter/board-filters.service';
import { CardViewHandlerRegistry } from 'core-app/features/work-packages/components/wp-card-view/event-handler/card-view-handler-registry';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { OpTitleService } from 'core-app/core/html/op-title.service';
import { OpProjectIncludeComponent } from 'core-app/shared/components/project-include/project-include.component';

export function boardCardViewHandlerFactory(injector:Injector) {
  return new CardViewHandlerRegistry(injector);
}

@Component({
  templateUrl: '../../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    '../../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass',
    './board-partitioned-page.component.sass',
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    DragAndDropService,
    BoardFiltersService,
  ],
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
  board$ = this
    .apiV3Service
    .boards
    .id(this.state.params.board_id.toString())
    .observe();

  /** Whether this is a new board just created */
  isNew = !!this.state.params.isNew;

  /** Whether the board is editable */
  editable:boolean;

  /** Go back to boards using back-button */
  backButtonCallback = () => this.state.go('boards');

  /** Current query title to render */
  selectedTitle?:string;

  currentQuery:QueryResource|undefined;

  /** Whether we're saving the board */
  toolbarDisabled = false;

  /** Do we currently have query props ? */
  showToolbarSaveButton:boolean;

  /** Listener callbacks */
  // eslint-disable-next-line @typescript-eslint/ban-types
  removeTransitionSubscription:Function;

  /** Show a toolbar */
  showToolbar = true;

  /** Whether filtering is allowed */
  filterAllowed = true;

  /** We need to pass the correct partition state to the view to manage the grid */
  currentPartition:ViewPartitionState = '-split';

  /** We need to apply our own board filter component */
  /** Which filter container component to mount */
  filterContainerDefinition:DynamicComponentDefinition = {
    component: BoardFilterComponent,
    inputs: {
      board$: this.board$,
    },
  };

  // We remember when we want to update the board
  boardSaver = new RequestSwitchmap(
    (board:Board) => {
      this.toolbarDisabled = true;
      return this.Boards
        .save(board)
        .pipe(
          finalize(() => (this.toolbarDisabled = false)),
        );
    },
  );

  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: WorkPackageFilterButtonComponent,
      containerClasses: 'hidden-for-mobile',
    },
    {
      component: OpProjectIncludeComponent,
    },
    {
      component: ZenModeButtonComponent,
      containerClasses: 'hidden-for-mobile',
    },
    {
      component: BoardsMenuButtonComponent,
      containerClasses: 'hidden-for-mobile',
      show: () => this.editable,
      inputs: {
        board$: this.board$,
      },
    },
  ];

  constructor(readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    readonly $transitions:TransitionService,
    readonly state:StateService,
    readonly toastService:ToastService,
    readonly halNotification:HalResourceNotificationService,
    readonly injector:Injector,
    readonly apiV3Service:ApiV3Service,
    readonly boardFilters:BoardFiltersService,
    readonly Boards:BoardService,
    readonly titleService:OpTitleService) {
    super();
  }

  ngOnInit():void {
    // Ensure board is being loaded
    this.Boards.loadAllBoards();

    this.boardSaver
      .observe(componentDestroyed(this))
      .subscribe(
        () => {
          this.toastService.addSuccess(this.text.updateSuccessful);
        },
        (error:unknown) => this.halNotification.handleRawError(error),
      );

    this.removeTransitionSubscription = this.$transitions.onSuccess({}, (transition):any => {
      const toState = transition.to();
      const params = transition.params('to');

      this.showToolbarSaveButton = !!params.query_props;
      this.setPartition(toState);

      this
        .board$
        .pipe(take(1))
        .subscribe((board) => {
          this.titleService.setFirstPart(board.name);
        });

      this.cdRef.detectChanges();
    });

    this.board$
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((board) => {
        const queryProps = this.state.params.query_props;
        this.editable = board.editable;
        this.selectedTitle = board.name;
        this.titleService.setFirstPart(board.name);
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
      .subscribe((board) => {
        board.name = newName;
        board.filters = this.boardFilters.current;

        const params = { isNew: false, query_props: null };
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
