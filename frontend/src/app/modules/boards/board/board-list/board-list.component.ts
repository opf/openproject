import {
  Component,
  ElementRef,
  EventEmitter, Inject, Injector,
  Input,
  OnChanges,
  OnDestroy,
  OnInit,
  Output,
  SimpleChanges,
  ViewChild
} from "@angular/core";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {
  LoadingIndicatorService,
  withLoadingIndicator
} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {componentDestroyed, untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {BoardInlineCreateService} from "core-app/modules/boards/board/board-list/board-inline-create.service";
import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {StateService} from "@uirouter/core";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {Board} from "core-app/modules/boards/board/board";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {AuthorisationService} from "core-app/modules/common/model-auth/model-auth.service";
import {Highlighting} from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import {WorkPackageCardViewComponent} from "core-components/wp-card-view/wp-card-view.component";
import {GonService} from "core-app/modules/common/gon/gon.service";
import {WorkPackageStatesInitializationService} from "core-components/wp-list/wp-states-initialization.service";
import {ApiV3Filter} from "core-components/api/api-v3/api-v3-filter-builder";
import {BoardService} from "app/modules/boards/board/board.service";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {WorkPackageFilterValues} from "core-components/wp-edit-form/work-package-filter-values";
import {IWorkPackageEditingServiceToken} from "core-components/wp-edit-form/work-package-editing.service.interface";
import {WorkPackageEditingService} from "core-components/wp-edit-form/work-package-editing-service";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";

@Component({
  selector: 'board-list',
  templateUrl: './board-list.component.html',
  styleUrls: ['./board-list.component.sass'],
  providers: [
    {provide: WorkPackageInlineCreateService, useClass: BoardInlineCreateService}
  ]
})
export class BoardListComponent extends AbstractWidgetComponent implements OnInit, OnDestroy, OnChanges {
  /** Output fired upon query removal */
  @Output() onRemove = new EventEmitter<void>();

  /** Access to the board resource */
  @Input() public board:Board;

  /** Access the filters of the board */
  @Input() public filters:ApiV3Filter[];

  /** Access to the loading indicator element */
  @ViewChild('loadingIndicator') indicator:ElementRef;

  /** Access to the card view */
  @ViewChild(WorkPackageCardViewComponent) cardView:WorkPackageCardViewComponent;

  /** The query resource being loaded */
  public query:QueryResource;

  /** Query loading error, if present */
  public loadingError:string|undefined;

  /** Rename inFlight */
  public inFlight:boolean;

  /** Whether the add button should be shown */
  public showAddButton = false;

  public columnsQueryProps:any;

  public text = {
    addCard: this.I18n.t('js.boards.add_card'),
    updateSuccessful: this.I18n.t('js.notice_successful_update'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
    unnamed_list: this.I18n.t('js.boards.label_unnamed_list'),
    click_to_remove: this.I18n.t('js.boards.click_to_remove_list')
  };

  /** Are we allowed to drag & drop elements ? */
  public dragAndDropEnabled:boolean = false;

  /** Initially focus the list */
  public initiallyFocused:boolean = false;

  /** Editing handler to be passed into card component */
  public workPackageAddedHandler = (workPackage:WorkPackageResource) => this.addWorkPackage(workPackage);

  constructor(private readonly QueryDm:QueryDmService,
              private readonly I18n:I18nService,
              private readonly state:StateService,
              private readonly boardCache:BoardCacheService,
              private readonly notifications:NotificationsService,
              private readonly querySpace:IsolatedQuerySpace,
              private readonly Gon:GonService,
              private readonly wpNotificationService:WorkPackageNotificationService,
              private readonly wpStatesInitialization:WorkPackageStatesInitializationService,
              private readonly authorisationService:AuthorisationService,
              private readonly wpInlineCreate:WorkPackageInlineCreateService,
              private readonly injector:Injector,
              @Inject(IWorkPackageEditingServiceToken) private readonly wpEditing:WorkPackageEditingService,
              private readonly loadingIndicator:LoadingIndicatorService,
              private readonly wpCacheService:WorkPackageCacheService,
              private readonly boardService:BoardService,
              private readonly boardListService:BoardListsService) {
    super(I18n);
  }

  ngOnInit():void {
    const boardId:string = this.state.params.board_id.toString();

    // Unset the isNew flag
    this.initiallyFocused = this.resource.isNew;
    this.resource.isNew = false;

    // Update permission on model updates
    this.authorisationService
      .observeUntil(componentDestroyed(this))
      .subscribe(() => {
        this.showAddButton = this.canManage && (this.wpInlineCreate.canAdd || this.canReference);
      });

    this.querySpace.query
      .values$()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((query) => this.query = query);

    this.boardCache
      .state(boardId.toString())
      .values$()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((board) => {
        this.dragAndDropEnabled = board.editable;
      });


    this.updateQuery();
  }

  ngOnDestroy():void {
    // Interface compatibility
  }

  ngOnChanges(changes:SimpleChanges) {
    // When the changes were caused by an actual filter change
    // and not by a change in lists
    if (changes.filters && !changes.resource) {
      this.updateQuery();
    }
  }

  public get errorMessage() {
    return this.I18n.t('js.boards.error_loading_the_list', { error_message: this.loadingError });
  }

  public get canReference() {
    return this.wpInlineCreate.canReference;
  }

  public get canManage() {
    return this.boardService.canManage(this.board);
  }

  public get canDelete() {
      return this.canManage && !!this.query.delete;
  }

  public get canRename() {
    return this.canManage && !!this.query.updateImmediately;
  }

  public addReferenceCard() {
    this.cardView.setReferenceMode(true);
  }

  public addNewCard() {
    this.cardView.addNewCard();
  }

  public deleteList(query?:QueryResource) {
    query = query ? query : this.query;

    if (!window.confirm(this.text.areYouSure)) {
      return;
    }

    this.QueryDm
      .delete(query)
      .then(() => this.onRemove.emit());
  }

  public renameQuery(query:QueryResource, value:string) {
    this.inFlight = true;
    this.query.name = value;
    this.QueryDm
      .patch(this.query.id!, {name: value})
      .toPromise()
      .then(() => {
        this.inFlight = false;
        this.notifications.addSuccess(this.text.updateSuccessful);
      })
      .catch(() => this.inFlight = false);
  }

  public boardListActionColorClass(query:QueryResource):string {
    const attribute = this.board.actionAttribute!;
    const filter = _.find(query.filters, f => f.id === attribute);

    if (!(filter && filter.values[0] instanceof HalResource)) {
      return '';
    }
    const value = filter.values[0] as HalResource;
    return Highlighting.rowClass(attribute, value.id!);
  }

  public get listName() {
    return this.query && this.query.name;
  }

  private updateQuery() {
    this.setQueryProps(this.filters);
    this.loadQuery();
  }

  /**
   * Handler to properly update the work package, when
   * adding to this query requires saving a changeset.
   * @param workPackage
   */
  private addWorkPackage(workPackage:WorkPackageResource) {
    let query = this.querySpace.query.value!;

    const changeset = this.wpEditing.changesetFor(workPackage);
    const filter = new WorkPackageFilterValues(this.injector, changeset, query.filters);
    filter.applyDefaultsFromFilters();

    if (changeset.empty) {
      // Ensure work package and its schema is loaded
      return this.wpCacheService.updateWorkPackage(workPackage);
    } else {
      // Save changes to the work package, which reloads it as well
      return changeset.save();
    }
  }

  private loadQuery() {
    const queryId:string = (this.resource.options.query_id as number|string).toString();

    this.QueryDm
      .stream(this.columnsQueryProps, queryId)
      .pipe(
        withLoadingIndicator(this.indicatorInstance, 50),
      )
      .subscribe(
        query => this.wpStatesInitialization.updateQuerySpace(query, query.results),
        error => this.loadingError = this.wpNotificationService.retrieveErrorMessage(error)
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
      'showHierarchies': false,
      'pageSize': 500,
      'filters': JSON.stringify(newFilters),
    };

    this.columnsQueryProps = newColumnsQueryProps;
  }
}
