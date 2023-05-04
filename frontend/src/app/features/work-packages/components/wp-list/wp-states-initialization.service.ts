import { States } from 'core-app/core/states/states.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { Injectable } from '@angular/core';
import { WorkPackageViewHighlightingService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { take } from 'rxjs/operators';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { WorkPackageViewDisplayRepresentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-display-representation.service';
import { WorkPackageViewIncludeSubprojectsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-include-subprojects.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { WorkPackageViewAdditionalElementsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-additional-elements.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewPaginationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-pagination.service';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { QuerySchemaResource } from 'core-app/features/hal/resources/query-schema-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { WorkPackagesListChecksumService } from './wp-list-checksum.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';

@Injectable()
export class WorkPackageStatesInitializationService {
  constructor(
    protected states:States,
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
    protected apiV3Service:ApiV3Service,
    protected wpListChecksumService:WorkPackagesListChecksumService,
    protected authorisationService:AuthorisationService,
    protected wpDisplayRepresentation:WorkPackageViewDisplayRepresentationService,
    protected wpIncludeSubprojects:WorkPackageViewIncludeSubprojectsService,
    protected wpTimestamps:WorkPackageViewBaselineService,
  ) { }

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

    // If the form is loaded, update it with the query
    const form = this.querySpace.queryForm.value;
    if (form) {
      this.updateStatesFromForm(query, form);
    }

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
      this.states.schemas.get(schema.href as string).putValue(schema as any);
    });

    this.wpTableFilters.initializeFilters(query, schema);
    this.querySpace.queryForm.putValue(form);

    this.querySpace.available.columns.putValue(schema.columns.allowedValues);
    this.querySpace.available.sortBy.putValue(schema.sortBy.allowedValues);
    this.querySpace.available.groupBy.putValue(schema.groupBy.allowedValues);
    this.querySpace.available.displayRepresentation.putValue(schema.displayRepresentation.allowedValues);
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

    results.elements.forEach((wp) => this.apiV3Service.work_packages.cache.updateWorkPackage(wp, true));

    this.querySpace.results.putValue(results);

    this.querySpace.groups.putValue(results.groups);

    this.wpTablePagination.initialize(query, results);

    this.wpTableRelationColumns.initialize(query, results);

    this.wpTableAdditionalElements.initialize(query, results);

    this.wpTableOrder.initialize(query, results);

    this.wpDisplayRepresentation.initialize(query, results);

    this.wpIncludeSubprojects.initialize(query, results);

    this.wpTimestamps.initialize(query, results);

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
    this.wpIncludeSubprojects.initialize(query, results);

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
    this.wpIncludeSubprojects.applyToQuery(query);
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
    this.wpIncludeSubprojects.clear(reason);
    this.wpTableSum.clear(reason);

    // Clear rendered state
    this.querySpace.tableRendered.clear(reason);
  }
}
