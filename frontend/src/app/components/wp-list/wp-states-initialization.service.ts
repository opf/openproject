import {States} from '../states.service';
import {WorkPackageTablePaginationService} from '../wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTableHierarchiesService} from '../wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTableTimelineService} from '../wp-fast-table/state/wp-table-timeline.service';
import {WorkPackageTableSumService} from '../wp-fast-table/state/wp-table-sum.service';
import {WorkPackageTableFiltersService} from '../wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableGroupByService} from '../wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTableColumnsService} from '../wp-fast-table/state/wp-table-columns.service';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {QueryFormResource} from 'core-app/modules/hal/resources/query-form-resource';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageTableRelationColumnsService} from '../wp-fast-table/state/wp-table-relation-columns.service';
import {WorkPackagesListChecksumService} from './wp-list-checksum.service';
import {WorkPackageTableSortByService} from '../wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableAdditionalElementsService} from '../wp-fast-table/state/wp-table-additional-elements.service';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {Injectable} from '@angular/core';
import {QuerySchemaResource} from 'core-app/modules/hal/resources/query-schema-resource';
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";

@Injectable()
export class WorkPackageStatesInitializationService {
  constructor(protected states:States,
              protected tableState:TableState,
              protected wpTableColumns:WorkPackageTableColumnsService,
              protected wpTableGroupBy:WorkPackageTableGroupByService,
              protected wpTableSortBy:WorkPackageTableSortByService,
              protected wpTableFilters:WorkPackageTableFiltersService,
              protected wpTableSum:WorkPackageTableSumService,
              protected wpTableTimeline:WorkPackageTableTimelineService,
              protected wpTableHierarchies:WorkPackageTableHierarchiesService,
              protected wpTableHighlighting:WorkPackageTableHighlightingService,
              protected wpTableRelationColumns:WorkPackageTableRelationColumnsService,
              protected wpTablePagination:WorkPackageTablePaginationService,
              protected wpTableAdditionalElements:WorkPackageTableAdditionalElementsService,
              protected wpCacheService:WorkPackageCacheService,
              protected wpListChecksumService:WorkPackagesListChecksumService,
              protected authorisationService:AuthorisationService) {
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

    // Update the (global) wp query states
    this.states.query.resource.putValue(query);
    this.initializeFromQuery(query, results);

    // Update the (local) table states
    this.updateTableState(query, results);

    // Ensure checksum for state is correct
    this.updateChecksum(query, results);
  }

  /**
   * Insert new information from the query from to the states.
   *
   * @param query
   * @param form
   */
  public updateStatesFromForm(query:QueryResource, form:QueryFormResource) {
    let schema:QuerySchemaResource = form.schema as any;

    _.each(schema.filtersSchemas.elements, (schema) => {
      this.states.schemas.get(schema.$href as string).putValue(schema as any);
    });

    this.wpTableFilters.initializeFilters(query, schema);
    this.states.query.form.putValue(form);

    this.states.query.available.columns.putValue(schema.columns.allowedValues);
    this.states.query.available.sortBy.putValue(schema.sortBy.allowedValues);
    this.states.query.available.groupBy.putValue(schema.groupBy.allowedValues);
  }

  public updateTableState(query:QueryResource, results:WorkPackageCollectionResource) {
    // Clear table required data states
    this.tableState.additionalRequiredWorkPackages.clear('Clearing additional WPs before updating rows');

    if (results.schemas) {
      _.each(results.schemas.elements, (schema:SchemaResource) => {
        this.states.schemas.get(schema.href as string).putValue(schema);
      });
    }
    this.tableState.query.putValue(query);

    this.tableState.rows.putValue(results.elements);

    this.wpCacheService.updateWorkPackageList(results.elements);

    this.tableState.results.putValue(results);

    this.tableState.groups.putValue(results.groups);

    this.wpTablePagination.initialize(query, results);

    this.wpTableRelationColumns.initialize();

    this.wpTableAdditionalElements.initialize(results.elements);
  }

  public updateChecksum(query:QueryResource, results:WorkPackageCollectionResource) {
    this.wpListChecksumService.updateIfDifferent(this.states.query.resource.value!, this.wpTablePagination.current);
    this.authorisationService.initModelAuth('work_packages', results.$links);
  }

  public initializeFromQuery(query:QueryResource, results:WorkPackageCollectionResource) {
    this.tableState.query.putValue(query);

    this.wpTableSum.initialize(query);
    this.wpTableColumns.initialize(query, results);
    this.wpTableSortBy.initialize(query, results);
    this.wpTableGroupBy.initialize(query, results);
    this.wpTableTimeline.initialize(query, results);
    this.wpTableHierarchies.initialize(query, results);
    this.wpTableHighlighting.initialize(query, results);

    this.authorisationService.initModelAuth('query', query.$links);
    this.authorisationService.initModelAuth('work_packages', results.$links);
  }

  public applyToQuery(query:QueryResource) {
    this.wpTableFilters.applyToQuery(query);
    this.wpTableSum.applyToQuery(query);
    this.wpTableColumns.applyToQuery(query);
    this.wpTableSortBy.applyToQuery(query);
    this.wpTableGroupBy.applyToQuery(query);
    this.wpTableTimeline.applyToQuery(query);
    this.wpTableHighlighting.applyToQuery(query);
    this.wpTableHierarchies.applyToQuery(query);
  }

  public clearStates() {
    const reason = 'Clearing states before re-initialization.';

    // Clear immediate input states
    this.tableState.query.clear(reason);
    this.tableState.rows.clear(reason);
    this.tableState.columns.clear(reason);
    this.tableState.sortBy.clear(reason);
    this.tableState.groupBy.clear(reason);
    this.tableState.sum.clear(reason);
    this.tableState.results.clear(reason);
    this.tableState.groups.clear(reason);
    this.tableState.additionalRequiredWorkPackages.clear(reason);

    // Clear rendered state
    this.tableState.rendered.clear(reason);
  }
}
