import {Component, ElementRef, Input, OnDestroy, OnInit, Query, ViewChild} from "@angular/core";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {
  LoadingIndicatorService,
  withLoadingIndicator
} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {WorkPackageTableConfigurationObject} from "core-components/wp-table/wp-table-configuration";
import {Observable, of, Subject} from "rxjs";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {
  auditTime,
  debounce,
  debounceTime,
  distinctUntilChanged, publishLast, refCount,
  share,
  shareReplay, take,
  tap,
  withLatestFrom
} from "rxjs/operators";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WpChildrenInlineCreateService} from "core-components/wp-relations/embedded/children/wp-children-inline-create.service";
import {BoardInlineCreateService} from "core-app/modules/boards/board/board-list/board-inline-create.service";
import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'board-list',
  templateUrl: './board-list.component.html',
  styleUrls: ['./board-list.component.sass'],
  providers: [
    { provide: WorkPackageInlineCreateService, useClass: BoardInlineCreateService }
  ]
})
export class BoardListComponent extends AbstractWidgetComponent implements OnInit, OnDestroy {

  /** Whether we use the card view */
  @Input() useCardView:boolean;

  /** Access to the loading indicator element */
  @ViewChild('loadingIndicator') indicator:ElementRef;

  /** The query resource being loaded */
  public query$:Observable<QueryResource>;

  /** Rename events */
  public rename$ = new Subject<string>();


  constructor(private readonly QueryDm:QueryDmService,
              private readonly I18n:I18nService,
              private readonly loadingIndicator:LoadingIndicatorService) {
    super(I18n);
  }

  ngOnInit():void {
    const queryId:number = this.resource.options.query_id as number;

    this.query$ = this.QueryDm
      .stream(this.columnsQueryProps, queryId)
      .pipe(
        withLoadingIndicator(this.indicatorInstance, 50),
        shareReplay()
      );

    this.rename$
      .pipe(
        untilComponentDestroyed(this),
        debounceTime(1000),
        distinctUntilChanged(),
        withLatestFrom(this.query$)
      )
      .subscribe(([newName, query]) => {
        query.name = newName;
        this.QueryDm.patch(query.id, { name: newName });
      });
  }

  ngOnDestroy():void {
    // Interface compatibility
  }

  get columnsQueryProps() {
    return {
      'columns[]': ['id', 'subject'],
      'showHierarchies': false,
      'pageSize': 500,
    };
  }

  get boardTableConfiguration():WorkPackageTableConfigurationObject {
    return {
      hierarchyToggleEnabled: false,
      columnMenuEnabled: false,
      actionsColumnEnabled: false,
      dragAndDropEnabled: true,
      isEmbedded: true,
      isCardView: this.useCardView
    };
  }

  private get indicatorInstance() {
    return this.loadingIndicator.indicator(jQuery(this.indicator.nativeElement));
  }
}
