import {AfterViewInit, Component, Input, OnDestroy, OnInit} from '@angular/core';
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
import {opUiComponentsModule} from 'core-app/angular-modules';
import {downgradeComponent} from '@angular/upgrade/static';

@Component({
  selector: 'wp-embedded-table',
  template: require('!!raw-loader!./wp-embedded-table.html'),
  providers: [
    TableState,
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
  ]
})
export class WorkPackageEmbeddedTableComponent implements OnInit, OnDestroy {
  @Input('queryId') public queryId:string;
  @Input() public configuration:boolean;

  private query:QueryResourceInterface;
  public tableInformationLoaded = false;
  public projectIdentifier = this.currentProject.identifier;

  constructor(readonly QueryDm:QueryDmService,
              readonly tableState:TableState,
              readonly wpStatesInitialization:WorkPackageStatesInitializationService,
              readonly currentProject:CurrentProjectService) {

  }

  ngOnInit():void {
    this.loadQuery().then((query:QueryResourceInterface) => {

      this.tableState.ready.doAndTransition('Query loaded', () => {
        this.wpStatesInitialization.initializeFromQuery(query, query.results);
        this.wpStatesInitialization.updateTableState(query, query.results);

        return this.tableState.tableRendering.onQueryUpdated.valuesPromise()
          .then(() => this.tableInformationLoaded = true);
      });
    });
  }

  ngOnDestroy():void {
  }

  private loadQuery():Promise<QueryResourceInterface> {
    return this.QueryDm.find(
      {},
      this.queryId,
      this.projectIdentifier || undefined
    );
  }

}

// TODO: remove as this should also work by angular2 only
opUiComponentsModule.directive(
  'wpEmbeddedTable',
  downgradeComponent({component: WorkPackageEmbeddedTableComponent})
);
