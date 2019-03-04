import {
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  OnDestroy,
  OnInit,
  Output,
  ViewChild
} from "@angular/core";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {
  LoadingIndicatorService,
  withLoadingIndicator
} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {BoardInlineCreateService} from "core-app/modules/boards/board/board-list/board-inline-create.service";
import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {StateService} from "@uirouter/core";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";

@Component({
  selector: 'board-list',
  templateUrl: './board-list.component.html',
  styleUrls: ['./board-list.component.sass'],
  providers: [
    {provide: WorkPackageInlineCreateService, useClass: BoardInlineCreateService}
  ]
})
export class BoardListComponent extends AbstractWidgetComponent implements OnInit, OnDestroy {
  /** Output fired upon query removal */
  @Output() onRemove = new EventEmitter<void>();

  /** Access to the loading indicator element */
  @ViewChild('loadingIndicator') indicator:ElementRef;

  /** The query resource being loaded */
  public query:QueryResource;

  /** Rename inFlight */
  public inFlight:boolean;

  public readonly columnsQueryProps = {
    'columns[]': ['id', 'subject'],
    'showHierarchies': false,
    'pageSize': 500,
  };

  public text = {
    updateSuccessful: this.I18n.t('js.notice_successful_update'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
  };

  public boardTableConfiguration = {
    hierarchyToggleEnabled: false,
    columnMenuEnabled: false,
    actionsColumnEnabled: false,
    // Drag & Drop is enabled when editable
    dragAndDropEnabled: false,
    isEmbedded: true,
    isCardView: true
  };

  constructor(private readonly QueryDm:QueryDmService,
              private readonly I18n:I18nService,
              private readonly state:StateService,
              private readonly boardCache:BoardCacheService,
              private readonly notifications:NotificationsService,
              private readonly cdRef:ChangeDetectorRef,
              private readonly querySpace:IsolatedQuerySpace,
              private readonly loadingIndicator:LoadingIndicatorService) {
    super(I18n);
  }

  ngOnInit():void {
    const boardId:number = this.state.params.board_id;

    this.loadQuery();

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
        this.boardTableConfiguration = {
          ...this.boardTableConfiguration,
          isCardView: board.displayMode === 'cards',
          dragAndDropEnabled: board.editable,
        };
      });
  }

  ngOnDestroy():void {
    // Interface compatibility
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
      .patch(this.query.id, {name: value})
      .then(() => {
        this.inFlight = false;
        this.notifications.addSuccess(this.text.updateSuccessful);
      })
      .catch(() => this.inFlight = false);
  }

  public get listName() {
    return this.query && this.query.name;
  }

  private loadQuery() {
    const queryId:number = this.resource.options.query_id as number;

    this.QueryDm
      .stream(this.columnsQueryProps, queryId)
      .pipe(
        withLoadingIndicator(this.indicatorInstance, 50),
      )
      .subscribe(query => this.query = query);
  }

  private get indicatorInstance() {
    return this.loadingIndicator.indicator(jQuery(this.indicator.nativeElement));
  }
}
