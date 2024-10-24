import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  Injector,
  Input,
  OnDestroy,
  OnInit,
  Output,
  ViewChild,
} from '@angular/core';
import {
  LoadingIndicatorService,
  withLoadingIndicator,
} from 'core-app/core/loading-indicator/loading-indicator.service';
import {
  WorkPackageInlineCreateService,
} from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { BoardInlineCreateService } from 'core-app/features/boards/board/board-list/board-inline-create.service';
import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { Board } from 'core-app/features/boards/board/board';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import {
  Highlighting,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import {
  WorkPackageCardViewComponent,
} from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import {
  WorkPackageStatesInitializationService,
} from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { BoardService } from 'core-app/features/boards/board/board.service';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import {
  BoardActionsRegistryService,
} from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';
import { ComponentType } from '@angular/cdk/portal';
import { CausedUpdatesService } from 'core-app/features/boards/board/caused-updates/caused-updates.service';
import { BoardListMenuComponent } from 'core-app/features/boards/board/board-list/board-list-menu.component';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import {
  WorkPackageCardDragAndDropService,
} from 'core-app/features/work-packages/components/wp-card-view/services/wp-card-drag-and-drop.service';
import { BoardFiltersService } from 'core-app/features/boards/board/board-filter/board-filters.service';
import { StateService, TransitionService } from '@uirouter/core';
import {
  WorkPackageViewFocusService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import {
  WorkPackageViewSelectionService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import {
  BoardListCrossSelectionService,
} from 'core-app/features/boards/board/board-list/board-list-cross-selection.service';
import { debounceTime, filter, map } from 'rxjs/operators';
import { ChangeItem } from 'core-app/shared/components/fields/changeset/changeset';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import {
  KeepTabService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { HalEvent, HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { firstValueFrom } from 'rxjs';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';

export interface DisabledButtonPlaceholder {
  text:string;
  icon:string;
}

@Component({
  selector: 'board-list',
  templateUrl: './board-list.component.html',
  styleUrls: ['./board-list.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  providers: [
    { provide: WorkPackageInlineCreateService, useClass: BoardInlineCreateService },
    BoardListMenuComponent,
    WorkPackageCardDragAndDropService,
  ],
})
export class BoardListComponent extends AbstractWidgetComponent implements OnInit, OnDestroy {
  /** Output fired upon query removal */
  @Output() onRemove = new EventEmitter<void>();

  /* Output fired after it is assured whether a user has the right to see the list */
  @Output() visibilityChange = new EventEmitter<boolean>();

  /** Access to the board resource */
  @Input() public board:Board;

  /** Access to the loading indicator element */
  @ViewChild('loadingIndicator', { static: true }) indicator:ElementRef;

  /** Access to the card view */
  @ViewChild(WorkPackageCardViewComponent) cardView:WorkPackageCardViewComponent;

  /** The query resource being loaded */
  public query:QueryResource;

  /** Query loading error, if present */
  public loadingError:string|undefined;

  /** The action attribute resource if any */
  public actionResource:HalResource|undefined;

  public actionResourceClass = '';

  public headerComponent:ComponentType<unknown>|undefined;

  /** Rename inFlight */
  public inFlight:boolean;

  /** Whether the add button should be shown */
  public showAddButton = false;

  private canAdd = firstValueFrom(this.wpInlineCreate.canAdd);

  public columnsQueryProps:any;

  public text = {
    addCard: this.I18n.t('js.boards.add_card'),
    updateSuccessful: this.I18n.t('js.notice_successful_update'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
    unnamed_list: this.I18n.t('js.boards.label_unnamed_list'),
    click_to_remove: this.I18n.t('js.boards.click_to_remove_list'),
  };

  /** Are we allowed to remove and drag & drop elements ? */
  public canDragInto = false;

  /** Initially focus the list */
  public initiallyFocused = false;

  /** Editing handler to be passed into card component */
  public workPackageAddedHandler = (workPackage:WorkPackageResource) => this.addWorkPackage(workPackage);

  /** Move check to be passed into card component */
  public canDragOutOf = false;

  public canDragOutOfHandler = (workPackage:WorkPackageResource) => this.canMove(workPackage);

  public buttonPlaceholder:DisabledButtonPlaceholder|undefined;

  constructor(readonly apiv3Service:ApiV3Service,
    readonly I18n:I18nService,
    readonly state:StateService,
    readonly cdRef:ChangeDetectorRef,
    readonly transitions:TransitionService,
    readonly boardFilters:BoardFiltersService,
    readonly toastService:ToastService,
    readonly querySpace:IsolatedQuerySpace,
    readonly halNotification:HalResourceNotificationService,
    readonly halEvents:HalEventsService,
    readonly wpStatesInitialization:WorkPackageStatesInitializationService,
    readonly wpViewFocusService:WorkPackageViewFocusService,
    readonly wpViewSelectionService:WorkPackageViewSelectionService,
    readonly boardListCrossSelectionService:BoardListCrossSelectionService,
    readonly authorisationService:AuthorisationService,
    readonly wpInlineCreate:WorkPackageInlineCreateService,
    readonly injector:Injector,
    readonly halEditing:HalResourceEditingService,
    readonly loadingIndicator:LoadingIndicatorService,
    readonly schemaCache:SchemaCacheService,
    readonly boardService:BoardService,
    readonly boardActionRegistry:BoardActionsRegistryService,
    readonly causedUpdates:CausedUpdatesService,
    readonly keepTab:KeepTabService,
    readonly $state:StateService) {
    super(I18n, injector);
  }

  ngOnInit():void {
    // Unset the isNew flag
    this.initiallyFocused = this.resource.isNewWidget;
    this.resource.isNewWidget = false;

    // Set initial selection if split view open
    if (this.state.includes(`${this.state.current.data.baseRoute}.details`)) {
      const wpId = this.state.params.workPackageId;
      this.wpViewSelectionService.initializeSelection([wpId]);
    }

    // If this query space changes its focused or selected
    // work packages, update the board cross selection
    this
      .wpViewSelectionService
      .updates$()
      .pipe(
        debounceTime(100),
        this.untilDestroyed(),
      )
      .subscribe((selectionState) => {
        const selected = Object.keys(_.pickBy(selectionState.selected, (option, _) => option === true));

        const focused = this.wpViewFocusService.focusedWorkPackage;

        this.boardListCrossSelectionService.updateSelection({
          withinQuery: this.queryId,
          focusedWorkPackage: focused,
          allSelected: selected,
        });
      });

    // Apply focus and selection when changed in cross service
    this.boardListCrossSelectionService
      .selectionsForQuery(this.queryId)
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((selection) => {
        this.wpViewSelectionService.initializeSelection(selection.allSelected);
      });

    // Update query on filter change
    this.boardFilters
      .filters
      .values$()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe(() => this.updateQuery(true));

    // Listen to changes to action attribute
    this.listenToActionAttributeChanges();

    this.querySpace.query
      .values$()
      .pipe(
        this.untilDestroyed(),
      )
      // eslint-disable-next-line @typescript-eslint/no-misused-promises
      .subscribe(async (query) => {
        this.query = query;
        this.canDragOutOf = !!this.query.updateOrderedWorkPackages;
        await this.loadActionAttribute(query);
        this.cdRef.detectChanges();
      });
  }

  ngOnDestroy() {
    super.ngOnDestroy();
  }

  public get errorMessage() {
    return this.I18n.t('js.boards.error_loading_the_list', { error_message: this.loadingError });
  }

  public canMove(workPackage:WorkPackageResource) {
    return this.canDragOutOf && (!this.actionService || this.actionService.canMove(workPackage));
  }

  public get canManage() {
    return this.boardService.canManage(this.board);
  }

  public get canRename() {
    return this.canManage
      && !!this.query.updateImmediately
      && this.board.isFree;
  }

  public addReferenceCard() {
    this.cardView.setReferenceMode(true);
  }

  public addNewCard() {
    this.cardView.addNewCard();
  }

  public deleteList(query?:QueryResource) {
    query = query || this.query;

    if (!window.confirm(this.text.areYouSure)) {
      return;
    }

    this
      .apiv3Service
      .queries
      .id(query)
      .delete()
      .subscribe(() => this.onRemove.emit());
  }

  public renameQuery(query:QueryResource, value:string) {
    this.inFlight = true;
    this.query.name = value;
    this
      .apiv3Service
      .queries
      .id(this.query)
      .patch({ name: value })
      .subscribe(
        () => {
          this.inFlight = false;
          this.toastService.addSuccess(this.text.updateSuccessful);
        },
        (_error) => this.inFlight = false,
      );
  }

  private boardListActionColorClass(value?:HalResource):string {
    const attribute = this.board.actionAttribute!;
    if (value && value.id) {
      return Highlighting.backgroundClass(attribute, value.id);
    }
    return '';
  }

  public get listName() {
    return this.query && this.query.name;
  }

  public showCardStatusButton() {
    return this.board.showStatusButton();
  }

  public refreshQueryUnlessCaused(query:QueryResource, visibly = true) {
    if (!this.causedUpdates.includes(query)) {
      debugLog(`Refreshing ${query.name} visibly due to external changes`);
      this.updateQuery(visibly);
    }
  }

  public updateQuery(visibly = true) {
    this.setQueryProps(this.boardFilters.current);
    this.loadQuery(visibly);
  }

  private async loadActionAttribute(query:QueryResource):Promise<void> {
    if (!this.board.isAction) {
      this.actionResource = undefined;
      this.headerComponent = undefined;
      this.canDragInto = !!query.updateOrderedWorkPackages;
      const canAdd = await this.canAdd;
      this.showAddButton = this.canDragInto && canAdd;
      return;
    }

    const actionService = this.actionService!;
    const id = actionService.getActionValueId(query);

    // Test if we loaded the resource already
    if (this.actionResource && id === this.actionResource.href) {
      return;
    }

    // Load the resource
    // eslint-disable-next-line consistent-return
    return actionService
      .getLoadedActionValue(query)
      .then(async (resource) => {
        this.actionResource = resource;
        this.headerComponent = actionService.headerComponent();
        this.buttonPlaceholder = actionService.disabledAddButtonPlaceholder(resource);
        this.actionResourceClass = this.boardListActionColorClass(resource);
        this.canDragInto = actionService.dragIntoAllowed(query, resource);

        const canWriteAttribute = await actionService.canAddToQuery(query);
        const canAdd = await this.canAdd;
        this.showAddButton = this.canDragInto && canAdd && canWriteAttribute;
        this.cdRef.detectChanges();
      });
  }

  /**
   * Return the linked action service
   */
  private get actionService():BoardActionService|undefined {
    if (this.board.actionAttribute) {
      return this.boardActionRegistry.get(this.board.actionAttribute);
    }

    return undefined;
  }

  /**
   * Handler to properly update the work package, when
   * adding to this query requires saving a changeset.
   * @param workPackage
   */
  private addWorkPackage(workPackage:WorkPackageResource) {
    const query = this.querySpace.query.value!;
    const changeset:WorkPackageChangeset = this.halEditing.changeFor(workPackage);

    // Assign to the action attribute if this is an action board
    this.actionService?.assignToWorkPackage(changeset, query);

    if (changeset.isEmpty()) {
      // Ensure work package and its schema is loaded
      return this.apiv3Service.work_packages.cache.updateWorkPackage(workPackage);
    }
    // Save changes to the work package, which reloads it as well
    return this.halEditing.save(changeset);
  }

  private get queryId():string {
    return (this.resource.options.queryId as number|string).toString();
  }

  private loadQuery(visibly = true) {
    let observable = this
      .apiv3Service
      .queries
      .find(this.columnsQueryProps, this.queryId);

    // Spread arguments on pipe does not work:
    // https://github.com/ReactiveX/rxjs/issues/3989
    if (visibly) {
      observable = observable.pipe(withLoadingIndicator(this.indicatorInstance, 50));
    }

    observable
      .subscribe(
        (query) => {
          this.wpStatesInitialization.updateQuerySpace(query, query.results);
        },
        (error) => {
          const userIsNotAllowedToSeeSubprojectError = 'urn:openproject-org:api:v3:errors:InvalidQuery';
          // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
          if (error.errorIdentifier === userIsNotAllowedToSeeSubprojectError) {
            this.visibilityChange.emit(false);
          }
          this.loadingError = this.halNotification.retrieveErrorMessage(error);
          this.cdRef.detectChanges();
        },
      );
  }

  private get indicatorInstance() {
    return this.loadingIndicator.indicator(jQuery(this.indicator.nativeElement));
  }

  private setQueryProps(filters:ApiV3Filter[]) {
    const existingFilters = (this.resource.options.filters || []) as ApiV3Filter[];

    const newFilters = existingFilters.concat(filters);
    const newColumnsQueryProps:any = {
      'columns[]': ['id', 'subject'],
      showHierarchies: false,
      pageSize: 500,
      filters: JSON.stringify(newFilters),
    };

    this.columnsQueryProps = newColumnsQueryProps;
  }

  private listenToActionAttributeChanges() {
    // If we don't have an action attribute
    // nothing to do
    if (!this.board.actionAttribute) {
      return;
    }

    // Listen to hal events to detect changes to an action attribute
    this.halEvents
      .events$
      .pipe(
        filter((event) => event.resourceType === 'WorkPackage'),
        // Only allow updates, otherwise this causes an error reloading the list
        // before the work package can be added to the query order
        filter((event) => event.eventType === 'updated'),
        map((event:HalEvent) => event.commit?.changes[this.actionService!.filterName]),
        filter((value) => !!value),
        filter((value:ChangeItem) => {
          // Compare the from and to values from the committed changes
          // with the current actionResource
          const current = this.actionResource?.href;
          const to = (value.to as HalResource|undefined)?.href;
          const from = (value.from as HalResource|undefined)?.href;

          return !!current && (current === to || current === from);
        }),
      )
      .subscribe(() => {
        this.updateQuery(true);
      });
  }

  openFullViewOnDoubleClick(event:{ workPackageId:string, double:boolean }) {
    if (event.double) {
      this.state.go(
        'work-packages.show',
        { workPackageId: event.workPackageId },
      );
    }
  }

  openStateLink(event:{ workPackageId:string; requestedState:string }) {
    const params = { workPackageId: event.workPackageId };

    if (event.requestedState === 'split') {
      this.keepTab.goCurrentDetailsState(params);
    } else {
      this.keepTab.goCurrentShowState(params.workPackageId);
    }
  }

  private schema(workPackage:WorkPackageResource) {
    return this.schemaCache.of(workPackage);
  }
}
