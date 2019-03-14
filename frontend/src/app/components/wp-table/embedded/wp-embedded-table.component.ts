import {AfterViewInit, Component, Injector, Input, OnDestroy, OnInit} from '@angular/core';
import {TableState} from '../table-state/table-state';
import {WorkPackageStatesInitializationService} from '../../wp-list/wp-states-initialization.service';
import {WorkPackageTableRelationColumnsService} from 'core-components/wp-fast-table/state/wp-table-relation-columns.service';
import {WorkPackageTableHierarchiesService} from 'core-components/wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTableTimelineService} from 'core-components/wp-fast-table/state/wp-table-timeline.service';
import {WorkPackageTablePaginationService} from 'core-components/wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTableGroupByService} from 'core-components/wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTableSortByService} from 'core-components/wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableFiltersService} from 'core-components/wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableColumnsService} from 'core-components/wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableSumService} from 'core-components/wp-fast-table/state/wp-table-sum.service';
import {WorkPackageTableAdditionalElementsService} from 'core-components/wp-fast-table/state/wp-table-additional-elements.service';
import {withLatestFrom} from 'rxjs/operators';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import { WorkPackageTableConfiguration } from 'core-components/wp-table/wp-table-configuration';
import {OpTableActionFactory} from 'core-components/wp-table/table-actions/table-action';
import {WorkPackageTableRefreshService} from 'core-components/wp-table/wp-table-refresh-request.service';
import {OpTableActionsService} from 'core-components/wp-table/table-actions/table-actions.service';
import {WorkPackageTableSelection} from 'core-components/wp-fast-table/state/wp-table-selection.service';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {QueryDmService} from 'core-app/modules/hal/dm-services/query-dm.service';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {WpTableConfigurationModalComponent} from 'core-components/wp-table/configuration-modal/wp-table-configuration.modal';
import {OpModalService} from 'core-components/op-modals/op-modal.service';
import {WorkPackageEmbeddedBaseComponent} from "core-components/wp-table/embedded/wp-embedded-base.component";
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {WorkPackageCreateService} from "core-components/wp-new/wp-create.service";
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";
import {WorkPackageTableFilters} from "core-components/wp-fast-table/wp-table-filters";

@Component({
  selector: 'wp-embedded-table',
  templateUrl: './wp-embedded-table.html',
  providers: [
    TableState,
    OpTableActionsService,
    WorkPackageTableRelationColumnsService,
    WorkPackageTablePaginationService,
    WorkPackageTableGroupByService,
    WorkPackageTableHierarchiesService,
    WorkPackageTableSortByService,
    WorkPackageTableColumnsService,
    WorkPackageTableFiltersService,
    WorkPackageTableTimelineService,
    WorkPackageTableSelection,
    WorkPackageTableSumService,
    WorkPackageTableAdditionalElementsService,
    WorkPackageTableRefreshService,
    WorkPackageTableHighlightingService,
    { provide: IWorkPackageCreateServiceToken, useClass: WorkPackageCreateService },
    // Order is important here, to avoid this service
    // getting global injections
    WorkPackageStatesInitializationService,
  ]
})
export class WorkPackageEmbeddedTableComponent extends WorkPackageEmbeddedBaseComponent implements OnInit, AfterViewInit, OnDestroy {
  @Input('queryId') public queryId?:number;
  @Input('queryProps') public queryProps:any = {};
  @Input() public tableActions:OpTableActionFactory[] = [];
  @Input() public compactTableStyle:boolean = false;
  @Input() public externalHeight:boolean = false;

  public show:boolean = true;
  public tableInformationLoaded = false;
  public showTablePagination = false;
  public configuration:WorkPackageTableConfiguration;
  public error:string|null = null;

  readonly QueryDm:QueryDmService = this.injector.get(QueryDmService);
  readonly opModalService:OpModalService = this.injector.get(OpModalService);
  readonly tableActionsService:OpTableActionsService = this.injector.get(OpTableActionsService);
  readonly wpTableTimeline:WorkPackageTableTimelineService = this.injector.get(WorkPackageTableTimelineService);
  readonly wpTablePagination:WorkPackageTablePaginationService = this.injector.get(WorkPackageTablePaginationService);

  constructor(injector:Injector) {
    super(injector);
  }

  ngAfterViewInit():void {
    super.ngAfterViewInit();

    // Provision embedded table actions
    if (this.tableActions) {
      this.tableActionsService.setActions(...this.tableActions);
    }

    // Reload results on changes to pagination
    this
      .tableState
      .ready.fireOnStateChange(this.wpTablePagination.state,
                       'Query loaded')
      .values$()
      .pipe(
        untilComponentDestroyed(this),
        withLatestFrom(this.tableState.query.values$())
      )
      .subscribe(([pagination, query]) => {
        this.refreshResults(query);
      });
  }

  public openConfigurationModal(onUpdated:() => void) {
    this.tableState.query
      .valuesPromise()
      .then(() => {
        const modal = this.opModalService
          .show<WpTableConfigurationModalComponent>(WpTableConfigurationModalComponent, {}, this.injector);

        // Detach this component when the modal closes and pass along the query data
        modal.onDataUpdated.subscribe(onUpdated);
      });
  }

  protected initializeStates(query:QueryResource, results:WorkPackageCollectionResource) {
    this.tableState.ready.doAndTransition('Query loaded', () => {
      this.wpStatesInitialization.clearStates();
      this.wpStatesInitialization.initializeFromQuery(query, results);
      this.wpStatesInitialization.updateTableState(query, results);

      return this.tableState.tableRendering.onQueryUpdated.valuesPromise()
        .then(() => {
          this.showTablePagination = results.total > results.count;
          this.setLoaded();

          // Disable compact mode when timeline active
          if (this.wpTableTimeline.isVisible) {
            this.compactTableStyle = false;
          }
        });
    });
  }

  public onFiltersChanged(filters:WorkPackageTableFilters) {
    // Nop
  }

  protected loadQuery(visible:boolean = true) {

    // HACK: Decrease loading time of queries when results are not needed.
    // We should allow the backend to disable results embedding instead.
    if (!this.configuration.tableVisible) {
      this.queryProps.pageSize = 1;
    } else if (this.configuration.forcePerPageOption) {
      // Limit the number of visible work packages
      this.queryProps.pageSize = this.configuration.forcePerPageOption;
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

  protected refreshResults(query:QueryResource) {
    this.loadingIndicator = this.QueryDm.loadResults(query, this.wpTablePagination.paginationObject)
      .then((results) => this.initializeStates(query, results));
  }
}
