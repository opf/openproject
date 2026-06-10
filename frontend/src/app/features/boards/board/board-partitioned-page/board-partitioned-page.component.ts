import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, Input, OnInit, inject } from '@angular/core';
import {
  DynamicComponentDefinition,
  ToolbarButtonComponentDefinition,
  ViewPartitionState,
} from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component';
import {
  StateService,
} from '@uirouter/core';
import { BoardFilterComponent } from 'core-app/features/boards/board/board-filter/board-filter.component';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { BoardService } from 'core-app/features/boards/board/board.service';
import { DragAndDropService } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { WorkPackageFilterButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-filter-button/wp-filter-button.component';
import { ZenModeButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import { BoardsMenuButtonComponent } from 'core-app/features/boards/board/toolbar-menu/boards-menu-button.component';
import {
  catchError,
  finalize,
  skip,
  take,
} from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { Board } from 'core-app/features/boards/board/board';
import { BoardFiltersService } from 'core-app/features/boards/board/board-filter/board-filters.service';
import { CardViewHandlerRegistry } from 'core-app/features/work-packages/components/wp-card-view/event-handler/card-view-handler-registry';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { OpTitleService } from 'core-app/core/html/op-title.service';
import { EMPTY, ReplaySubject } from 'rxjs';
import { SubmenuService } from 'core-app/core/main-menu/submenu.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

export function boardCardViewHandlerFactory(injector:Injector) {
  return new CardViewHandlerRegistry(injector);
}

@Component({
  selector: 'board-partitioned-page',
  templateUrl: '../../../work-packages/routing/partitioned-query-space-page/primerized-partitioned-query-space-page.component.html',
  styleUrls: [
    '../../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass',
    './board-partitioned-page.component.sass',
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    DragAndDropService,
    BoardFiltersService,
  ],
  standalone: false,
})
export class BoardPartitionedPageComponent extends UntilDestroyedMixin implements OnInit {
  readonly I18n = inject(I18nService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly state = inject(StateService);
  readonly toastService = inject(ToastService);
  readonly halNotification = inject(HalResourceNotificationService);
  readonly injector = inject(Injector);
  readonly apiV3Service = inject(ApiV3Service);
  readonly boardFilters = inject(BoardFiltersService);
  readonly Boards = inject(BoardService);
  readonly titleService = inject(OpTitleService);
  readonly submenuService = inject(SubmenuService);
  readonly pathHelperService = inject(PathHelperService);
  readonly currentProject = inject(CurrentProjectService);

  @Input() boardId:string;
  text = {
    button_more: this.I18n.t('js.button_more'),
    delete: this.I18n.t('js.button_delete'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
    deleteSuccessful: this.I18n.t('js.notice_successful_delete'),
    updateSuccessful: this.I18n.t('js.notice_successful_update'),
    unnamedBoard: this.I18n.t('js.boards.label_unnamed_board'),
    loadingError: 'No such board found',
    addList: this.I18n.t('js.boards.add_list'),
    upsellBoards: this.I18n.t('js.boards.upsell.teaser_text'),
    upsellCheckOutLink: this.I18n.t('js.work_packages.table_configuration.upsell.check_out_link'),
    unnamed_list: this.I18n.t('js.boards.label_unnamed_list'),
  };

  /** Board subject */
  board$ = new ReplaySubject<Board>(1);

  /** Whether the board is editable */
  editable:boolean;

  /** Current query title to render */
  selectedTitle?:string;

  currentQuery:QueryResource|undefined;

  /** Whether we're saving the board */
  toolbarDisabled = false;

  /** Do we currently have query props ? */
  showToolbarSaveButton:boolean;

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

  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: WorkPackageFilterButtonComponent,
      containerClasses: 'hidden-for-tablet',
    },
    {
      component: ZenModeButtonComponent,
      containerClasses: 'hidden-for-tablet',
    },
    {
      component: BoardsMenuButtonComponent,
      containerClasses: 'hidden-for-tablet',
      show: () => this.editable,
      inputs: {
        board$: this.board$,
      },
    },
  ];

  ngOnInit():void {
    // Ensure board is being loaded
    this.Boards.loadAllBoards();

    const boardId = this.boardId || this.state.params.board_id?.toString();
    this.apiV3Service.boards.id(boardId).observe()
      .pipe(this.untilDestroyed())
      .subscribe((board) => this.board$.next(board));

    // React to filter changes (board-filter updates boardFilters after pushing URL)
    this.boardFilters.filters.values$()
      .pipe(
        this.untilDestroyed(),
        skip(1), // skip the initial empty default value
      )
      .subscribe(() => {
        this.showToolbarSaveButton = !!new URLSearchParams(window.location.search).get('query_props');
        this.cdRef.detectChanges();
      });

    this.board$
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((board) => {
        const queryProps = new URLSearchParams(window.location.search).get('query_props');
        this.editable = board.editable;
        this.selectedTitle = board.name;
        this.titleService.setFirstPart(board.name);
        this.boardFilters.filters.putValue(queryProps ? JSON.parse(queryProps) : board.filters);

        this.cdRef.detectChanges();
      });
  }

  breadcrumbItems() {
    return [
      { href: this.pathHelperService.projectPath(this.currentProject.identifier!), text: (this.currentProject.name) },
      { href: this.pathHelperService.boardsPath(this.currentProject.identifier), text: this.I18n.t('js.label_board_plural') },
      this.selectedTitle?? '',
    ];
  }

  currentMenuSectionHeader() { return this.I18n.t('js.label_global_queries'); }

  changeChangesFromTitle(newName:string) {
    this.board$
      .pipe(take(1))
      .subscribe((board) => {
        board.name = newName;
        board.filters = this.boardFilters.current;

        const url = new URL(window.location.href);
        url.searchParams.delete('query_props');
        window.history.pushState({}, '', url);
        this.showToolbarSaveButton = false;

        this.toolbarDisabled = true;
        this.Boards
          .save(board)
          .pipe(
            catchError((error) => {
              this.halNotification.handleRawError(error);
              return EMPTY;
            }),
            finalize(() => {
              this.toolbarDisabled = false;
              this.cdRef.detectChanges();
              this.reloadSidemenu();
            }),
          ).subscribe(() => {
            this.toastService.addSuccess(this.text.updateSuccessful);
          },
        );
      });
  }

  updateTitleName(val:string) {
    this.changeChangesFromTitle(val);
  }

  /** Whether the title can be edited */
  get titleEditingEnabled():boolean {
    return this.editable;
  }

  private reloadSidemenu():void {
    this.submenuService.reloadSubmenu(null, 'boards_sidemenu');
  }
}
