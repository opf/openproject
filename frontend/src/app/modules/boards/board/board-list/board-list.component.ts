import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  OnDestroy,
  OnInit,
  ViewChild
} from "@angular/core";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {
  LoadingIndicatorService,
  withLoadingIndicator
} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {Observable, Subject} from "rxjs";
import {debounceTime, distinctUntilChanged, shareReplay, skip, skipUntil, withLatestFrom} from "rxjs/operators";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {BoardInlineCreateService} from "core-app/modules/boards/board/board-list/board-inline-create.service";
import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {StateService} from "@uirouter/core";
import {Board} from "core-app/modules/boards/board/board";

@Component({
  selector: 'board-list',
  templateUrl: './board-list.component.html',
  styleUrls: ['./board-list.component.sass'],
  providers: [
    {provide: WorkPackageInlineCreateService, useClass: BoardInlineCreateService}
  ]
})
export class BoardListComponent extends AbstractWidgetComponent implements OnInit, OnDestroy {

  /** Access to the loading indicator element */
  @ViewChild('loadingIndicator') indicator:ElementRef;

  /** The query resource being loaded */
  public query$:Observable<QueryResource>;

  /** Rename events */
  public rename$ = new Subject<string>();

  public readonly columnsQueryProps = {
    'columns[]': ['id', 'subject'],
    'showHierarchies': false,
    'pageSize': 500,
  };

  public boardTableConfiguration = {
    hierarchyToggleEnabled: false,
    columnMenuEnabled: false,
    actionsColumnEnabled: false,
    dragAndDropEnabled: true,
    isEmbedded: true,
    isCardView: true
  };

  constructor(private readonly QueryDm:QueryDmService,
              private readonly I18n:I18nService,
              private readonly state:StateService,
              private readonly boardCache:BoardCacheService,
              private readonly cdRef:ChangeDetectorRef,
              private readonly loadingIndicator:LoadingIndicatorService) {
    super(I18n);
  }

  ngOnInit():void {
    let first = true;
    const boardId:number = this.state.params.board_id;

    this.boardCache
      .state(boardId.toString())
      .values$()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((board) => {
        this.initialize(board, first);
        first = false;
      });
  }

  ngOnDestroy():void {
    // Interface compatibility
  }

  private initialize(board:Board, first:boolean) {
    this.boardTableConfiguration = {
      ...this.boardTableConfiguration,
      isCardView: board.displayMode === 'cards'
    };

    this.loadQuery();

    if (!first) {
      return;
    }

    this.rename$
      .pipe(
        untilComponentDestroyed(this),
        debounceTime(1000),
        distinctUntilChanged(),
        withLatestFrom(this.query$)
      )
      .subscribe(([newName, query]) => {
        query.name = newName;
        this.QueryDm.patch(query.id, {name: newName});
      });
  }

  private loadQuery() {
    const queryId:number = this.resource.options.query_id as number;

    this.query$ = this.QueryDm
      .stream(this.columnsQueryProps, queryId)
      .pipe(
        withLoadingIndicator(this.indicatorInstance, 50),
        shareReplay(1)
      );
  }

  private get indicatorInstance() {
    return this.loadingIndicator.indicator(jQuery(this.indicator.nativeElement));
  }
}
