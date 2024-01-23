import {
  derive,
  input,
  InputState,
  multiInput,
  State,
  StatesGroup,
} from '@openproject/reactivestates';
import { Subject } from 'rxjs';
import { Injectable } from '@angular/core';
import { map } from 'rxjs/operators';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import {
  GroupObject,
  WorkPackageCollectionResource,
} from 'core-app/features/hal/resources/wp-collection-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageDisplayRepresentationValue } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-display-representation.service';
import { QueryFilterInstanceSchemaResource } from 'core-app/features/hal/resources/query-filter-instance-schema-resource';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { QuerySortByResource } from 'core-app/features/hal/resources/query-sort-by-resource';
import { QueryGroupByResource } from 'core-app/features/hal/resources/query-group-by-resource';
import { ShareResource } from 'core-app/features/hal/resources/share-resource';

@Injectable()
export class IsolatedQuerySpace extends StatesGroup {
  name = 'IsolatedQuerySpace';

  // The query that results in this table state
  query:InputState<QueryResource> = input<QueryResource>();

  // the query form associated with the table
  queryForm = input<QueryFormResource>();

  // the results associated with the table/time-entry-changeset
  results = input<WorkPackageCollectionResource>();

  // all groups returned as results
  groups = input<GroupObject[]>();

  // Set of columns in strict order of appearance
  columns = input<QueryColumn[]>();

  // Current state of collapsed groups (if any)
  collapsedGroups = input<{ [identifier:string]:boolean }>();

  // State to be updated when the table is up to date
  tableRendered = input<RenderedWorkPackage[]>();

  // Event to be raised when the timeline is up to date
  timelineRendered = new Subject<null>();

  renderedWorkPackages:State<RenderedWorkPackage[]> = derive(this.tableRendered, ($) => $.pipe(
    map((rows) => rows.filter((row) => !!row.workPackageId)),
  ));

  renderedWorkPackageIds:State<string[]> = derive(this.renderedWorkPackages, ($) => $.pipe(
    map((rows) => rows.map((row) => row.workPackageId!.toString())),
  ));

  // Subject used to unregister all listeners of states above.
  stopAllSubscriptions = new Subject<void>();

  // Required work packages to be rendered by hierarchy mode + relation columns
  additionalRequiredWorkPackages = input<null>();

  // Cached shares for work packages
  workPackageSharesCache = multiInput<ShareResource[]>();

  // Input state that emits whenever table services have initialized
  initialized = input<unknown>();

  // Available states
  available = {
    // Available columns
    columns: input<QueryColumn[]>(),

    // Available SortBy Columns
    sortBy: input<QuerySortByResource[]>(),

    // Available GroupBy columns
    groupBy: input<QueryGroupByResource[]>(),

    // Available filter schemas (derived from their schema)
    filters: input<QueryFilterInstanceSchemaResource[]>(),

    // Display of the WP results
    displayRepresentation: input<WorkPackageDisplayRepresentationValue|null>(),
  };
}
