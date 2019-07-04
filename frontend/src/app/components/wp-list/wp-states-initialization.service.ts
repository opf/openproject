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
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {Injectable} from '@angular/core';
import {QuerySchemaResource} from 'core-app/modules/hal/resources/query-schema-resource';
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {combineLatest, Observable} from "rxjs";
import {take} from "rxjs/operators";
import {WorkPackageTableOrderService} from "core-components/wp-fast-table/state/wp-table-order.service";

@Injectable()
export class WorkPackageStatesInitializationService {
  constructor(protected states:States,
              protected querySpace:IsolatedQuerySpace,
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
              protected wpTableOrder:WorkPackageTableOrderService,
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
    this.querySpace.query.putValue(query);
    this.initializeFromQuery(query, results);

    // Update the (local) table states
    this.updateQuerySpace(query, results);

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
    this.querySpace.queryForm.putValue(form);

    this.states.queries.columns.putValue(schema.columns.allowedValues);
    this.states.queries.sortBy.putValue(schema.sortBy.allowedValues);
    this.states.queries.groupBy.putValue(schema.groupBy.allowedValues);
  }

  public updateQuerySpace(query:QueryResource, results:WorkPackageCollectionResource) {
    // Clear table required data states
    this.querySpace.additionalRequiredWorkPackages.clear('Clearing additional WPs before updating rows');

    if (results.schemas) {
      _.each(results.schemas.elements, (schema:SchemaResource) => {
        this.states.schemas.get(schema.href as string).putValue(schema);
      });
    }
    this.querySpace.query.putValue(query);

    this.authorisationService.initModelAuth('work_packages', results.$links);

    results.elements.forEach(wp => this.wpCacheService.updateWorkPackage(wp, true));

    this.querySpace.results.putValue(results);

    this.querySpace.groups.putValue(results.groups);

    this.wpTablePagination.initialize(query, results);

    this.wpTableRelationColumns.initialize(query, results);

    this.wpTableAdditionalElements.initialize(results.elements);

    this.wpTableOrder.initialize(query, results);

    this.querySpace.additionalRequiredWorkPackages
      .values$()
      .pipe(take(1))
      .subscribe(() => this.querySpace.initialized.putValue(null));
  }

  public updateChecksum(query:QueryResource, results:WorkPackageCollectionResource) {
    this.wpListChecksumService.updateIfDifferent(this.querySpace.query.value!, this.wpTablePagination.current);
    this.authorisationService.initModelAuth('work_packages', results.$links);
  }

  public initializeFromQuery(query:QueryResource, results:WorkPackageCollectionResource) {
    this.querySpace.query.putValue(query);

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
    this.wpTableOrder.applyToQuery(query);
  }

  public clearStates() {
    const reason = 'Clearing states before re-initialization.';

    // Clear immediate input states
    this.querySpace.initialized.clear(reason);
    this.querySpace.query.clear(reason);
    this.querySpace.results.clear(reason);
    this.querySpace.groups.clear(reason);
    this.querySpace.additionalRequiredWorkPackages.clear(reason);

    this.wpTableFilters.clear(reason);
    this.wpTableColumns.clear(reason);
    this.wpTableSortBy.clear(reason);
    this.wpTableGroupBy.clear(reason);
    this.wpTableSum.clear(reason);

    // Clear rendered state
    this.querySpace.rendered.clear(reason);
  }
}
