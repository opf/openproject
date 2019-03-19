import {RenderedRow} from 'app/components/wp-fast-table/builders/primary-render-pass';
import {WorkPackageTableHierarchies} from 'app/components/wp-fast-table/wp-table-hierarchies';
import {WorkPackageTablePagination} from 'app/components/wp-fast-table/wp-table-pagination';
import {WorkPackageTableRelationColumns} from 'app/components/wp-fast-table/wp-table-relation-columns';
import {WorkPackageTableTimelineState} from 'app/components/wp-fast-table/wp-table-timeline';
import {WPTableRowSelectionState} from 'app/components/wp-fast-table/wp-table.interfaces';
import {combine, derive, DerivedState, input, InputState, State, StatesGroup} from 'reactivestates';
import {Subject} from 'rxjs';
import {Injectable} from '@angular/core';
import {SwitchState} from 'core-components/states/switch-state';
import {map, mapTo} from 'rxjs/operators';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {GroupObject, WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageTableHighlight} from "core-components/wp-fast-table/wp-table-highlight";
import {QueryFormResource} from "core-app/modules/hal/resources/query-form-resource";
import {WPFocusState} from "core-components/wp-fast-table/state/wp-table-focus.service";
import {QueryColumn} from "core-components/wp-query/query-column";
import {QueryFilterInstanceResource} from "core-app/modules/hal/resources/query-filter-instance-resource";
import {QueryGroupByResource} from "core-app/modules/hal/resources/query-group-by-resource";
import {QuerySortByResource} from "core-app/modules/hal/resources/query-sort-by-resource";
import {WorkPackageTableRefreshRequest} from "core-components/wp-table/wp-table-refresh-request.service";

@Injectable()
export class IsolatedQuerySpace extends StatesGroup {

  constructor() {
    super();
  }

  name = 'IsolatedQuerySpace';

  // The query that results in this table state
  query:InputState<QueryResource> = input<QueryResource>();

  // the query form associated with the table
  queryForm = input<QueryFormResource>();

  // the results associated with the table
  results = input<WorkPackageCollectionResource>();
  // Set of work package IDs in strict order of appearance
  rows = input<WorkPackageResource[]>();
  // all groups returned as results
  groups = input<GroupObject[]>();
  // Set of columns in strict order of appearance
  columns = input<QueryColumn[]>();

  // Set of filters
  filters = input<QueryFilterInstanceResource[]>();
  // Active and available sort by
  sortBy = input<QuerySortByResource[]>();
  // Active and available group by
  groupBy = input<QueryGroupByResource|null>();
  // is query summed
  sum = input<boolean>();
  // pagination information
  pagination = input<WorkPackageTablePagination>();
  // Table row selection state
  selection = input<WPTableRowSelectionState>();
  // Current state of collapsed groups (if any)
  collapsedGroups = input<{ [identifier:string]:boolean }>();
  // Hierarchies of table
  hierarchies = input<WorkPackageTableHierarchies>();
  // Highlighting mode
  highlighting = input<WorkPackageTableHighlight>();
  // State to be updated when the table is up to date
  rendered = input<RenderedRow[]>();

  renderedWorkPackages:State<RenderedRow[]> = derive(this.rendered, $ => $.pipe(
    map(rows => rows.filter(row => !!row.workPackageId)))
  );

  // Current focused work package (e.g, row preselected for details button)
  focusedWorkPackage:InputState<WPFocusState> = input<WPFocusState>();

  // State to determine timeline visibility
  timeline = input<WorkPackageTableTimelineState>();

  // Subject used to unregister all listeners of states above.
  stopAllSubscriptions = new Subject();
  // Fire when table refresh is required
  refreshRequired = input<WorkPackageTableRefreshRequest>();

  // Expanded relation columns
  relationColumns = input<WorkPackageTableRelationColumns>();

  // Required work packages to be rendered by hierarchy mode + relation columns
  additionalRequiredWorkPackages = input<null>();

  tableRendering = new TableRenderingStates(this);

  // Current context of table loading
  ready = new SwitchState<'Query loaded'>();

  // Updater states on user input
  updates = new UserUpdaterStates(this);
}

export class TableRenderingStates {
  constructor(private querySpace:IsolatedQuerySpace) {
  }

  // State when all required input states for the current query are ready
  private combinedquerySpaces = combine(
    this.querySpace.rows,
    this.querySpace.columns,
    this.querySpace.sum,
    this.querySpace.sortBy,
    this.querySpace.groupBy,
    this.querySpace.additionalRequiredWorkPackages
  );

  onQueryUpdated:DerivedState<unknown[], [undefined], null, undefined> =
    derive(this.combinedquerySpaces, ($, ) => $.pipe(mapTo(null)));
}

export class UserUpdaterStates {

  constructor(private querySpace:IsolatedQuerySpace) {
  }

  columnsUpdates = this.querySpace.ready.fireOnStateChange(this.querySpace.columns,
    'Query loaded');

  hierarchyUpdates = this.querySpace.ready.fireOnStateChange(this.querySpace.hierarchies,
    'Query loaded');

  relationUpdates = this.querySpace.ready.fireOnStateChange(this.querySpace.relationColumns,
    'Query loaded');
}
