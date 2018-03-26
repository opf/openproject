import {Component, Input, OnDestroy, OnInit} from '@angular/core';
import {QueryDmService} from '../../api/api-v3/hal-resource-dms/query-dm.service';
import {CurrentProjectService} from '../../projects/current-project.service';
import {
  QueryResource,
  QueryResourceInterface
} from '../../api/api-v3/hal-resources/query-resource.service';
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
import {WorkPackageCollectionResource} from 'core-components/api/api-v3/hal-resources/wp-collection-resource.service';
import {WorkPackageTableConfigurationObject} from 'core-components/wp-table/wp-table-configuration';
import {OpTableActionFactory} from 'core-components/wp-table/table-actions/table-action';
import {WorkPackageTableRefreshService} from 'core-components/wp-table/wp-table-refresh-request.service';
import {OpTableActionsService} from 'core-components/wp-table/table-actions/table-actions.service';
import {opUiComponentsModule} from 'core-app/angular-modules';
import {downgradeComponent} from '@angular/upgrade/static';

@Component({
  selector: 'wp-embedded-table',
  template: require('!!raw-loader!./wp-embedded-table.html'),
  providers: [
    TableState,
    OpTableActionsService,
    WorkPackageStatesInitializationService,
    WorkPackageTableRelationColumnsService,
    WorkPackageTablePaginationService,
    WorkPackageTableGroupByService,
    WorkPackageTableHierarchiesService,
    WorkPackageTableSortByService,
    WorkPackageTableColumnsService,
    WorkPackageTableFiltersService,
    WorkPackageTableTimelineService,
    WorkPackageTableSumService,
    WorkPackageTableAdditionalElementsService,
    WorkPackageTableRefreshService,
  ]
})
export class WorkPackageEmbeddedTableComponent implements OnInit, OnDestroy {
  @Input('queryId') public queryId?:string;
  @Input('queryProps') public queryProps:any = {};
  @Input() public configuration:WorkPackageTableConfigurationObject;
  @Input() public tableActions?:OpTableActionFactory[];

  private query:QueryResourceInterface;
  public tableInformationLoaded = false;
  public showTablePagination = false;

  constructor(readonly QueryDm:QueryDmService,
              readonly tableState:TableState,
              readonly tableActionsService:OpTableActionsService,
              readonly wpTablePagination:WorkPackageTablePaginationService,
              readonly wpStatesInitialization:WorkPackageStatesInitializationService,
              readonly currentProject:CurrentProjectService) {

  }

  ngOnInit():void {
    // Provision embedded table actions
    if (this.tableActions) {
      this.tableActionsService.setActions(...this.tableActions);
    }

    // Load initial query
    this.loadQuery();

    // Reload results on changes to pagination
    this.tableState.ready.fireOnStateChange(this.wpTablePagination.state,
      'Query loaded').values$().pipe(
      untilComponentDestroyed(this),
      withLatestFrom(this.tableState.query.values$())
    ).subscribe(([pagination, query]) => {
      this.QueryDm.loadResults(query, this.wpTablePagination.paginationObject)
        .then((results) => this.initializeStates(query, results));
      });
  }

  ngOnDestroy():void {
  }

  get projectIdentifier() {
    let identifier:string|null = null;

    if (this.configuration['projectContext']) {
      identifier = this.currentProject.identifier;
    }

    return identifier || undefined;
  }

  private initializeStates(query:QueryResource, results:WorkPackageCollectionResource) {
    this.tableState.ready.doAndTransition('Query loaded', () => {
      this.wpStatesInitialization.clearStates();
      this.wpStatesInitialization.initializeFromQuery(query, results);
      this.wpStatesInitialization.updateTableState(query, results);

      return this.tableState.tableRendering.onQueryUpdated.valuesPromise()
        .then(() => {
          this.showTablePagination = results.total > results.count;
          this.tableInformationLoaded = true;
        });
    });
  }

  public refresh(visibly = true) {
    // TODO loading indicator
    this.loadQuery();
  }

  private loadQuery() {
    this.QueryDm
      .find(
        this.queryProps,
        this.queryId,
        this.projectIdentifier
      )
      .then((query:QueryResourceInterface) => this.initializeStates(query, query.results));
  }
}

// TODO: remove as this should also work by angular2 only
opUiComponentsModule.directive(
  'wpEmbeddedTable',
  downgradeComponent({component: WorkPackageEmbeddedTableComponent})
);
