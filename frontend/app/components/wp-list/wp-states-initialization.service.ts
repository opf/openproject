import {States} from '../states.service';
import {WorkPackagesListInvalidQueryService} from './wp-list-invalid-query.service';
import {WorkPackageTablePaginationService} from '../wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTableHierarchiesService} from '../wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTableTimelineService} from '../wp-fast-table/state/wp-table-timeline.service';
import {WorkPackageTableSumService} from '../wp-fast-table/state/wp-table-sum.service';
import {WorkPackageTableFiltersService} from '../wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableGroupByService} from '../wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTableSortByService} from '../wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableColumnsService} from '../wp-fast-table/state/wp-table-columns.service';
import {QueryResource} from '../api/api-v3/hal-resources/query-resource.service';
import {WorkPackageCollectionResource} from '../api/api-v3/hal-resources/wp-collection-resource.service';
import {SchemaResource} from '../api/api-v3/hal-resources/schema-resource.service';
import {QueryFormResource} from '../api/api-v3/hal-resources/query-form-resource.service';
import {QuerySchemaResourceInterface} from '../api/api-v3/hal-resources/query-schema-resource.service';
import {QueryFilterInstanceSchemaResource} from '../api/api-v3/hal-resources/query-filter-instance-schema-resource.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';

export class WorkPackageStatesInitializationService {
  constructor(protected states:States,
              protected wpTableColumns:WorkPackageTableColumnsService,
              protected wpTableSortBy:WorkPackageTableSortByService,
              protected wpTableGroupBy:WorkPackageTableGroupByService,
              protected wpTableFilters:WorkPackageTableFiltersService,
              protected wpTableSum:WorkPackageTableSumService,
              protected wpTableTimeline:WorkPackageTableTimelineService,
              protected wpTableHierarchies:WorkPackageTableHierarchiesService,
              protected wpTablePagination:WorkPackageTablePaginationService,
              protected wpListInvalidQueryService:WorkPackagesListInvalidQueryService,
              protected wpCacheService:WorkPackageCacheService,
              protected AuthorisationService:any) {
  }

  /**
   * Initialize the query and table states from the given query and results.
   * They may or may not come from the same query source.
   *
   * @param query
   * @param results
   */
  public initialize(query:QueryResource, results:WorkPackageCollectionResource) {
    this.clearStates();

    this.initializeFromQuery(query);
    this.initializeFromResults(results);
  }

  /**
   * Insert new information from the query from to the states.
   *
   * @param query
   * @param form
   */
  public updateStatesFromForm(query:QueryResource, form:QueryFormResource) {
    let schema = form.schema as QuerySchemaResourceInterface;

    _.each(schema.filtersSchemas.elements, (schema:QueryFilterInstanceSchemaResource) => {
      this.states.schemas.get(schema.href as string).putValue(schema);
    });

    this.states.table.form.putValue(form);
    this.wpTableSortBy.initialize(query, schema);
    this.wpTableFilters.initialize(query, schema);
    this.wpTableGroupBy.update(query, schema);
    this.wpTableColumns.update(query, schema);
  }

  private initializeFromResults(results:WorkPackageCollectionResource) {
    if (results.schemas) {
      _.each(results.schemas.elements, (schema:SchemaResource) => {
        this.states.schemas.get(schema.href as string).putValue(schema);
      });
    }

    this.states.table.rows.putValue(results.elements);

    this.wpCacheService.updateWorkPackageList(results.elements);

    this.states.table.results.putValue(results);

    this.states.table.groups.putValue(angular.copy(results.groups));

    this.wpTablePagination.initialize(results);

    this.AuthorisationService.initModelAuth('work_packages', results.$links);
  }

  private initializeFromQuery(query:QueryResource) {
    this.states.table.query.putValue(query);

    this.wpTableSum.initialize(query);
    this.wpTableColumns.initialize(query);
    this.wpTableGroupBy.initialize(query);
    this.wpTableTimeline.initialize(query);
    this.wpTableHierarchies.initialize(query);

    this.AuthorisationService.initModelAuth('query', query.$links);
  }

  private clearStates() {
    const reason = 'Clearing states before re-initialization.';

    // Clear table states
    this.wpTableSum.clear(reason)
    this.wpTableColumns.clear(reason);
    this.wpTableGroupBy.clear(reason);
    this.wpTableTimeline.clear(reason);
    this.wpTableHierarchies.clear(reason);

    // Clear immediate input states
    this.states.table.rows.clear(reason);
    this.states.table.results.clear(reason);
    this.states.table.groups.clear(reason);
  }
}

angular
  .module('openproject.workPackages.services')
  .service('wpStatesInitialization', WorkPackageStatesInitializationService);
