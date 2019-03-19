import {
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter, Input, OnChanges,
  OnDestroy,
  OnInit,
  Output, SimpleChanges,
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
import {
  IQueryFilterInstanceSource,
  QueryFilterInstanceResource
} from "core-app/modules/hal/resources/query-filter-instance-resource";
import {UrlParamsHelperService} from "core-components/wp-query/url-params-helper";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";

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
  @Input() public filters:QueryFilterInstanceResource[];

  /** Access to the loading indicator element */
  @ViewChild('loadingIndicator') indicator:ElementRef;

  /** Access to the card view */
  @ViewChild(WorkPackageCardViewComponent) cardView:WorkPackageCardViewComponent;

  /** The query resource being loaded */
  public query:QueryResource;

  /** Rename inFlight */
  public inFlight:boolean;

  /** Whether the add button should be shown */
  public showAddButton = false;

  public columnsQueryProps:any;

  public text = {
    addCard: this.I18n.t('js.boards.add_card'),
    updateSuccessful: this.I18n.t('js.notice_successful_update'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
  };

  /** Are we allowed to drag & drop elements ? */
  public dragAndDropEnabled:boolean = false;

  constructor(private readonly QueryDm:QueryDmService,
              private readonly I18n:I18nService,
              private readonly state:StateService,
              private readonly boardCache:BoardCacheService,
              private readonly notifications:NotificationsService,
              private readonly cdRef:ChangeDetectorRef,
              private readonly querySpace:IsolatedQuerySpace,
              private readonly Gon:GonService,
              private readonly wpStatesInitialization:WorkPackageStatesInitializationService,
              private readonly authorisationService:AuthorisationService,
              private readonly wpInlineCreate:WorkPackageInlineCreateService,
              private readonly loadingIndicator:LoadingIndicatorService,
              private readonly urlParamsHelperService:UrlParamsHelperService,
              private readonly halResourceService:HalResourceService) {
    super(I18n);
  }

  ngOnInit():void {
    const boardId:string = this.state.params.board_id;

    // Update permission on model updates
    this.authorisationService
      .observeUntil(componentDestroyed(this))
      .subscribe(() => {
        this.showAddButton = this.wpInlineCreate.canAdd || this.canReference;
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
  }

  ngOnDestroy():void {
    // Interface compatibility
  }

  ngOnChanges(changes:SimpleChanges) {
    if(changes.filters) {
      this.setQueryProps(this.filters);
      this.loadQuery();
    }
  }

  public get canReference() {
    return this.wpInlineCreate.canReference &&  !!this.Gon.get('permission_flags', 'edit_work_packages');
  }

  public addReferenceCard() {
    this.cardView.setReferenceMode(true);
  }

  public addNewCard() {
    this.cardView.addNewCard();
  }

  public deleteList(query:QueryResource) {
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

  private loadQuery() {
    const queryId:string = (this.resource.options.query_id as number|string).toString();

    this.QueryDm
      .stream(this.columnsQueryProps, queryId)
      .pipe(
        withLoadingIndicator(this.indicatorInstance, 50),
      )
      .subscribe(query => {
        this.wpStatesInitialization.updateQuerySpace(query, query.results);
      });
  }

  private get indicatorInstance() {
    return this.loadingIndicator.indicator(jQuery(this.indicator.nativeElement));
  }

  private setQueryProps(filters:QueryFilterInstanceResource[]) {
    const existingFilters = this.instantiateFilters(this.resource.options.filters || []);

    const newFilters = existingFilters.concat(filters);
    const newColumnsQueryProps:any = {
      'columns[]': ['id', 'subject'],
      'showHierarchies': false,
      'pageSize': 500,
    };

    if (newFilters.length > 0) {
      newColumnsQueryProps.filters = this.urlParamsHelperService.buildV3GetFiltersAsJson(newFilters);
    }

    this.columnsQueryProps = newColumnsQueryProps;
  }

  private instantiateFilters(filters:IQueryFilterInstanceSource[]):QueryFilterInstanceResource[] {
    return filters.map(source => {
      return this.halResourceService.createHalResourceOfType<QueryFilterInstanceResource>('QueryFilterInstance', source);
    })
  }
}
