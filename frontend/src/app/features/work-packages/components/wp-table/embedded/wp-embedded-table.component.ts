import { AfterViewInit, Component, EventEmitter, Input, OnDestroy, OnInit, Output } from '@angular/core';
import {
  WorkPackageViewTimelineService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import {
  WorkPackageViewPaginationService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-pagination.service';
import { OpTableActionFactory } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import {
  OpTableActionsService,
} from 'core-app/features/work-packages/components/wp-table/table-actions/table-actions.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import {
  WpTableConfigurationModalComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/wp-table-configuration.modal';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import {
  WorkPackageEmbeddedBaseComponent,
} from 'core-app/features/work-packages/components/wp-table/embedded/wp-embedded-base.component';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { distinctUntilChanged, map, take, withLatestFrom } from 'rxjs/operators';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import {
  KeepTabService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { firstValueFrom } from 'rxjs';
import { QueryRequestParams } from 'core-app/features/work-packages/components/wp-query/url-params-helper';

@Component({
  selector: 'wp-embedded-table',
  templateUrl: './wp-embedded-table.html',
})
export class WorkPackageEmbeddedTableComponent extends WorkPackageEmbeddedBaseComponent implements OnInit, AfterViewInit, OnDestroy {
  @Input('queryId') public queryId?:string;

  @Input('queryProps') public queryProps:Partial<QueryRequestParams> = {};

  @Input() public tableActions:OpTableActionFactory[] = [];

  @Input() public externalHeight = false;

  /** Inform about loading errors */
  @Output() public onError = new EventEmitter<string>();

  /** Inform about loaded query */
  @Output() public onQueryLoaded = new EventEmitter<QueryResource>();

  @InjectField() apiv3Service:ApiV3Service;

  @InjectField() opModalService:OpModalService;

  @InjectField() tableActionsService:OpTableActionsService;

  @InjectField() wpTableTimeline:WorkPackageViewTimelineService;

  @InjectField() wpTablePagination:WorkPackageViewPaginationService;

  @InjectField() keepTab:KeepTabService;

  // Cache the form promise
  private formPromise:Promise<QueryFormResource|undefined>|undefined;

  // If the query was provided to use via the query space,
  // use it to cache first loading
  private loadedQuery:QueryResource|undefined;

  ngOnInit() {
    super.ngOnInit();
    this.loadedQuery = this.querySpace.query.value;
  }

  ngAfterViewInit():void {
    super.ngAfterViewInit();

    // Provision embedded table actions
    if (this.tableActions) {
      this.tableActionsService.setActions(...this.tableActions);
    }

    // Reload results on changes to pagination (Regression #29845)
    this.wpTablePagination
      .updates$()
      .pipe(
        map((pagination) => [pagination.page, pagination.perPage]),
        distinctUntilChanged(),
        this.untilDestroyed(),
        withLatestFrom(this.querySpace.query.values$()),
      ).subscribe(([_, query]) => {
      const pagination = this.wpTablePagination.paginationObject;
      const params = this.urlParamsHelper.buildV3GetQueryFromQueryResource(query, pagination);

      this.loadingIndicator = firstValueFrom(
        this
          .wpListService
          .loadQueryFromExisting(query, params, this.queryProjectScope),
      )
        .then((query) => this.initializeStates(query));
    });
  }

  public async openConfigurationModal(onUpdated:() => void):Promise<void> {
    await this.querySpace.query.valuesPromise();

    this.opModalService
      .show(WpTableConfigurationModalComponent, this.injector)
      // Detach this component when the modal closes and pass along the query data
      .subscribe((modal) => modal.onDataUpdated.subscribe(onUpdated));
  }

  protected initializeStates(query:QueryResource) {
    super.initializeStates(query);

    this.querySpace
      .initialized
      .values$()
      .pipe(take(1))
      .subscribe(() => {
        this.showTablePagination = query.results.total > query.results.count;
        this.setLoaded();

        // Disable compact mode when timeline active
        if (this.wpTableTimeline.isVisible) {
          this.configuration = { ...this.configuration, compactTableStyle: false };
        }
      });
  }

  public loadQuery(visible = true, firstPage = false):Promise<QueryResource> {

    if (this.loadedQuery) {
      const query = this.loadedQuery;
      this.loadedQuery = undefined;
      this.initializeStates(query);
      return Promise.resolve(query);
    }

    // HACK: Decrease loading time of queries when results are not needed.
    // We should allow the backend to disable results embedding instead.
    if (!this.configuration.tableVisible) {
      this.queryProps.pageSize = 1;
      // Also use a valid subset to ensure we get a valid response.
      this.queryProps.valid_subset = true;
    }

    // Set first page
    if (firstPage) {
      this.queryProps.page = 1;
    }

    this.error = null;
    const promise = this
      .apiv3Service
      .queries
      .find(
        this.queryProps,
        this.queryId,
        this.queryProjectScope,
      )
      .toPromise()
      .then((query:QueryResource) => {
        this.initializeStates(query);
        this.onQueryLoaded.emit(query);
        return query;
      })
      .catch((error) => {
        this.error = this.I18n.t(
          'js.error.embedded_table_loading',
          { message: _.get(error, 'message', error) },
        );
        this.onError.emit(error);
      });

    if (visible) {
      this.loadingIndicator = promise;
    }

    return promise as Promise<QueryResource>;
  }

  handleWorkPackageClicked(event:{ workPackageId:string; double:boolean }) {
    if (event.double) {
      this.$state.go(
        'work-packages.show',
        { workPackageId: event.workPackageId },
      );
    }
  }

  openStateLink(event:{ workPackageId:string; requestedState:'show'|'split' }) {
    const params = {
      workPackageId: event.workPackageId,
      focus: true,
    };

    if (event.requestedState === 'split') {
      this.keepTab.goCurrentDetailsState(params);
    } else {
      this.keepTab.goCurrentShowState(params);
    }
  }
}
