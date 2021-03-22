import { States } from '../states.service';
import { QueryResource } from 'core-app/modules/hal/resources/query-resource';
import { WorkPackageCollectionResource } from 'core-app/modules/hal/resources/wp-collection-resource';
import { SchemaResource } from 'core-app/modules/hal/resources/schema-resource';
import { QueryFormResource } from 'core-app/modules/hal/resources/query-form-resource';
import { WorkPackagesListChecksumService } from './wp-list-checksum.service';
import { AuthorisationService } from 'core-app/modules/common/model-auth/model-auth.service';
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { Injectable } from '@angular/core';
import { QuerySchemaResource } from 'core-app/modules/hal/resources/query-schema-resource';
import { WorkPackageViewHighlightingService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-highlighting.service";
import { take } from "rxjs/operators";
import { WorkPackageViewOrderService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-order.service";
import { WorkPackageViewDisplayRepresentationService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import { WorkPackageViewSumService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-sum.service";
import { WorkPackageViewColumnsService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service";
import { WorkPackageViewSortByService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-sort-by.service";
import { WorkPackageViewAdditionalElementsService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-additional-elements.service";
import { WorkPackageViewHierarchiesService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy.service";
import { WorkPackageViewPaginationService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-pagination.service";
import { WorkPackageViewTimelineService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service";
import { WorkPackageViewGroupByService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-group-by.service";
import { WorkPackageViewFiltersService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import { WorkPackageViewRelationColumnsService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-relation-columns.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { WorkPackageViewCollapsedGroupsService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service";

@Injectable()
export class WorkPackageStatesInitializationService {
  constructor(protected states:States,
              protected querySpace:IsolatedQuerySpace,
              protected wpTableColumns:WorkPackageViewColumnsService,
              protected wpTableGroupBy:WorkPackageViewGroupByService,
              protected wpTableGroupFold:WorkPackageViewCollapsedGroupsService,
              protected wpTableSortBy:WorkPackageViewSortByService,
              protected wpTableFilters:WorkPackageViewFiltersService,
              protected wpTableSum:WorkPackageViewSumService,
              protected wpTableTimeline:WorkPackageViewTimelineService,
              protected wpTableHierarchies:WorkPackageViewHierarchiesService,
              protected wpTableHighlighting:WorkPackageViewHighlightingService,
              protected wpTableRelationColumns:WorkPackageViewRelationColumnsService,
              protected wpTablePagination:WorkPackageViewPaginationService,
              protected wpTableOrder:WorkPackageViewOrderService,
              protected wpTableAdditionalElements:WorkPackageViewAdditionalElementsService,
              protected apiV3Service:APIV3Service,
              protected wpListChecksumService:WorkPackagesListChecksumService,
              protected authorisationService:AuthorisationService,
              protected wpDisplayRepresentation:WorkPackageViewDisplayRepresentationService) {
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
    const schema:QuerySchemaResource = form.schema as any;

    _.each(schema.filtersSchemas.elements, (schema) => {
      this.states.schemas.get(schema.$href as string).putValue(schema as any);
    });

    this.wpTableFilters.initializeFilters(query, schema);
    this.querySpace.queryForm.putValue(form);

    this.states.queries.columns.putValue(schema.columns.allowedValues);
    this.states.queries.sortBy.putValue(schema.sortBy.allowedValues);
    this.states.queries.groupBy.putValue(schema.groupBy.allowedValues);
    this.states.queries.displayRepresentation.putValue(schema.displayRepresentation.allowedValues);
  }

  public updateQuerySpace(query:QueryResource, results:WorkPackageCollectionResource) {
    // Clear table required data states
    this.querySpace.additionalRequiredWorkPackages.clear('Clearing additional WPs before updating rows');
    this.querySpace.tableRendered.clear('Clearing rendered data before upgrading query space');

    if (results.schemas) {
      _.each(results.schemas.elements, (schema:SchemaResource) => {
        this.states.schemas.get(schema.href as string).putValue(schema);
      });
    }

    this.querySpace.query.putValue(query);

    this.authorisationService.initModelAuth('work_packages', results.$links);

    results.elements.forEach(wp => this.apiV3Service.work_packages.cache.updateWorkPackage(wp, true));

    this.querySpace.results.putValue(results);

    this.querySpace.groups.putValue(results.groups);

    this.wpTablePagination.initialize(query, results);

    this.wpTableRelationColumns.initialize(query, results);

    this.wpTableAdditionalElements.initialize(query, results);

    this.wpTableOrder.initialize(query, results);

    this.wpDisplayRepresentation.initialize(query, results);

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
    this.wpTableGroupFold.initialize(query, results);
    this.wpTableTimeline.initialize(query, results);
    this.wpTableHierarchies.initialize(query, results);
    this.wpTableHighlighting.initialize(query, results);
    this.wpDisplayRepresentation.initialize(query, results);

    this.authorisationService.initModelAuth('query', query.$links);
    this.authorisationService.initModelAuth('work_packages', results.$links);
  }

  public applyToQuery(query:QueryResource) {
    this.wpTableFilters.applyToQuery(query);
    this.wpTableSum.applyToQuery(query);
    this.wpTableColumns.applyToQuery(query);
    this.wpTableSortBy.applyToQuery(query);
    this.wpTableGroupBy.applyToQuery(query);
    this.wpTableGroupFold.applyToQuery(query);
    this.wpTableTimeline.applyToQuery(query);
    this.wpTableHighlighting.applyToQuery(query);
    this.wpTableHierarchies.applyToQuery(query);
    this.wpTableOrder.applyToQuery(query);
    this.wpDisplayRepresentation.applyToQuery(query);
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
    this.wpTableGroupFold.clear(reason);
    this.wpDisplayRepresentation.clear(reason);
    this.wpTableSum.clear(reason);

    // Clear rendered state
    this.querySpace.tableRendered.clear(reason);
  }
}
