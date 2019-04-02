import {AfterViewInit, Component, Input, OnDestroy, OnInit} from '@angular/core';
import {WorkPackageTableTimelineService} from 'core-components/wp-fast-table/state/wp-table-timeline.service';
import {WorkPackageTablePaginationService} from 'core-components/wp-fast-table/state/wp-table-pagination.service';
import {OpTableActionFactory} from 'core-components/wp-table/table-actions/table-action';
import {OpTableActionsService} from 'core-components/wp-table/table-actions/table-actions.service';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {QueryDmService} from 'core-app/modules/hal/dm-services/query-dm.service';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {WpTableConfigurationModalComponent} from 'core-components/wp-table/configuration-modal/wp-table-configuration.modal';
import {OpModalService} from 'core-components/op-modals/op-modal.service';
import {WorkPackageEmbeddedBaseComponent} from "core-components/wp-table/embedded/wp-embedded-base.component";
import {QueryFormResource} from "core-app/modules/hal/resources/query-form-resource";
import {QueryFormDmService} from "core-app/modules/hal/dm-services/query-form-dm.service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {withLatestFrom} from "rxjs/internal/operators";

@Component({
  selector: 'wp-embedded-table',
  templateUrl: './wp-embedded-table.html'
})
export class WorkPackageEmbeddedTableComponent extends WorkPackageEmbeddedBaseComponent implements OnInit, AfterViewInit, OnDestroy {
  @Input('queryId') public queryId?:string;
  @Input('queryProps') public queryProps:any = {};
  @Input() public tableActions:OpTableActionFactory[] = [];
  @Input() public externalHeight:boolean = false;

  readonly QueryDm:QueryDmService = this.injector.get(QueryDmService);
  readonly opModalService:OpModalService = this.injector.get(OpModalService);
  readonly tableActionsService:OpTableActionsService = this.injector.get(OpTableActionsService);
  readonly wpTableTimeline:WorkPackageTableTimelineService = this.injector.get(WorkPackageTableTimelineService);
  readonly wpTablePagination:WorkPackageTablePaginationService = this.injector.get(WorkPackageTablePaginationService);
  readonly QueryFormDm:QueryFormDmService = this.injector.get(QueryFormDmService);

  // Cache the form promise
  private formPromise:Promise<QueryFormResource>|undefined;

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
    this.querySpace.ready.fireOnStateChange(
      this.wpTablePagination.state,
      'Query loaded'
    ).values$().pipe(
      untilComponentDestroyed(this),
      withLatestFrom(this.querySpace.query.values$())
    ).subscribe(([pagination, query]) => {
      this.loadingIndicator = this.QueryDm
        .loadResults(query, this.wpTablePagination.paginationObject)
        .then((results) => this.initializeStates(query, results));
    });
  }

  public openConfigurationModal(onUpdated:() => void) {
    this.querySpace.query
      .valuesPromise()
      .then(() => {
        const modal = this.opModalService
          .show(WpTableConfigurationModalComponent, this.injector);

        // Detach this component when the modal closes and pass along the query data
        modal.onDataUpdated.subscribe(onUpdated);
      });
  }

  private initializeStates(query:QueryResource, results:WorkPackageCollectionResource) {

    // If the configuration requests filters, we need to load the query form as well.
    if (this.configuration.withFilters) {
      this.loadForm(query);
    }

    this.querySpace.ready.doAndTransition('Query loaded', () => {
      this.wpStatesInitialization.clearStates();
      this.wpStatesInitialization.initializeFromQuery(query, results);
      this.wpStatesInitialization.updateQuerySpace(query, results);

      return this.querySpace.tableRendering.onQueryUpdated.valuesPromise()
        .then(() => {
          this.showTablePagination = results.total > results.count;
          this.setLoaded();

          // Disable compact mode when timeline active
          if (this.wpTableTimeline.isVisible) {
            this.configuration = { ...this.configuration, compactTableStyle: false };
          }
        });
    });
  }

  private loadForm(query:QueryResource):Promise<QueryFormResource> {
    if (this.formPromise) {
      return this.formPromise;
    }

    return this.formPromise = this.QueryFormDm
      .load(query)
      .then((form:QueryFormResource) => {
        this.wpStatesInitialization.updateStatesFromForm(query, form);
        return form;
      })
      .catch(() => this.formPromise = undefined);
  }

  public loadQuery(visible:boolean = true, firstPage:boolean = false):Promise<QueryResource> {
    // Ensure we are loading the form.
    this.formPromise = undefined;

    if (this.loadedQuery) {
      const query = this.loadedQuery;
      this.loadedQuery = undefined;
      this.initializeStates(query, query.results);
      return Promise.resolve(this.loadedQuery!);
    }


    // HACK: Decrease loading time of queries when results are not needed.
    // We should allow the backend to disable results embedding instead.
    if (!this.configuration.tableVisible) {
      this.queryProps.pageSize = 1;
    } else if (this.configuration.forcePerPageOption) {
      // Limit the number of visible work packages
      this.queryProps.pageSize = this.configuration.forcePerPageOption;
    }

    // Set first page
    if (firstPage) {
      this.queryProps.page = 1;
    }

    this.error = null;
    const promise = this.QueryDm
      .find(
        this.queryProps,
        this.queryId,
        this.queryProjectScope
      )
      .then((query:QueryResource) => {
        this.initializeStates(query, query.results);
        return query;
      })
      .catch((error) => {
        this.error = this.I18n.t(
          'js.error.embedded_table_loading',
          { message: _.get(error, 'message', error) }
        );
      });

    if (visible) {
      this.loadingIndicator = promise;
    }

    return promise;
  }
}
