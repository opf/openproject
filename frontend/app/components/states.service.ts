import {
  combine,
  createNewContext,
  derive,
  input,
  multiInput,
  State,
  StatesGroup
} from 'reactivestates';
import {Subject} from 'rxjs';
import {opServicesModule} from '../angular-modules';
import {QueryFormResource} from './api/api-v3/hal-resources/query-form-resource.service';
import {QueryResource} from './api/api-v3/hal-resources/query-resource.service';
import {SchemaResource} from './api/api-v3/hal-resources/schema-resource.service';
import {TypeResource} from './api/api-v3/hal-resources/type-resource.service';
import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from './api/api-v3/hal-resources/work-package-resource.service';
import {
  GroupObject,
  WorkPackageCollectionResource
} from './api/api-v3/hal-resources/wp-collection-resource.service';
import {WorkPackageEditForm} from './wp-edit-form/work-package-edit-form';
import {WorkPackageTableColumns} from './wp-fast-table/wp-table-columns';
import {WorkPackageTableFilters} from './wp-fast-table/wp-table-filters';
import {WorkPackageTableGroupBy} from './wp-fast-table/wp-table-group-by';
import {WorkPackageTableHierarchies} from './wp-fast-table/wp-table-hierarchies';
import {WorkPackageTablePagination} from './wp-fast-table/wp-table-pagination';
import {WorkPackageTableSortBy} from './wp-fast-table/wp-table-sort-by';
import {WorkPackageTableSum} from './wp-fast-table/wp-table-sum';
import {WorkPackageTableTimelineState} from './wp-fast-table/wp-table-timeline';
import {RenderedRow} from './wp-fast-table/builders/primary-render-pass';
import {SwitchState} from './states/switch-state';
import {QueryColumn} from './wp-query/query-column';
import {QuerySortByResource} from './api/api-v3/hal-resources/query-sort-by-resource.service';
import {QueryGroupByResource} from './api/api-v3/hal-resources/query-group-by-resource.service';
import {WPTableRowSelectionState} from './wp-fast-table/wp-table.interfaces';
import {WorkPackageTableRelationColumns} from './wp-fast-table/wp-table-relation-columns';

export class States extends StatesGroup {

  name = "MainStore";
  /* /api/v3/work_packages */
  workPackages = multiInput<WorkPackageResourceInterface>();

  /* /api/v3/schemas */
  schemas = multiInput<SchemaResource>();

  /* /api/v3/types */
  types = multiInput<TypeResource>();

  // Work package table states
  table = new TableState();

  // Work Package query states
  query = new QueryStates();

  tableRendering = new TableRenderingStates(this);

  // Updater states on user input
  updates = new UserUpdaterStates(this);

  // Current focused work package (e.g, row preselected for details button)
  focusedWorkPackage = input<string>();

}

export class TableState extends StatesGroup {

  name = "TableStore";

  // the results associated with the table
  results = input<WorkPackageCollectionResource>();
  // Set of work package IDs in strict order of appearance
  rows = input<WorkPackageResource[]>();
  // all groups returned as results
  groups = input<GroupObject[]>();
  // Set of columns in strict order of appearance
  columns = input<WorkPackageTableColumns>();

  // Set of filters
  filters = input<WorkPackageTableFilters>();
  // Active and available sort by
  sortBy = input<WorkPackageTableSortBy>();
  // Active and available group by
  groupBy = input<WorkPackageTableGroupBy>();
  // is query summed
  sum = input<WorkPackageTableSum>();
  // pagination information
  pagination = input<WorkPackageTablePagination>();
  // Table row selection state
  selection = input<WPTableRowSelectionState>();
  // Current state of collapsed groups (if any)
  collapsedGroups = input<{[identifier:string]: boolean}>();
  // Hierarchies of table
  hierarchies = input<WorkPackageTableHierarchies>();
  // State to be updated when the table is up to date
  rendered = input<RenderedRow[]>();

  renderedWorkPackages: State<RenderedRow[]> = derive(this.rendered, $ => $
    .map(rows => rows.filter(row => !!row.workPackageId)));

  // State to determine timeline visibility
  timelineVisible = input<WorkPackageTableTimelineState>();
  // Subject used to unregister all listeners of states above.
  stopAllSubscriptions = new Subject();
  // Fire when table refresh is required
  refreshRequired = input<boolean>();

  // Expanded relation columns
  relationColumns = input<WorkPackageTableRelationColumns>();

  // Required work packages to be rendered by hierarchy mode + relation columns
  additionalRequiredWorkPackages = input<null>();
}

export class QueryStates {

  // Current context of table loading
  context = new SwitchState<'Query loaded'>();

  // the query associated with the table
  resource = input<QueryResource>();

  // the query form associated with the table
  form = input<QueryFormResource>();

  // Keep available data
  available = new QueryAvailableDataStates();
}

export class QueryAvailableDataStates {
  // Available columns
  columns = input<QueryColumn[]>();

  // Available SortBy Columns
  sortBy = input<QuerySortByResource[]>();

  // Available GroupBy columns
  groupBy = input<QueryGroupByResource[]>();

  // Filters remain special, since they require their schema to be loaded
  // Thus the table state is not initialized until all values are available.
}

export class TableRenderingStates {
  constructor(private states:States) {
  }

  // State when all required input states for the current query are ready
  private combinedTableStates = combine(
    this.states.table.rows,
    this.states.table.columns,
    this.states.table.sum,
    this.states.table.groupBy,
    this.states.table.sortBy,
    this.states.table.additionalRequiredWorkPackages
  );

  onQueryUpdated = derive(this.combinedTableStates, ($, input) => $.mapTo(null));

}

export class UserUpdaterStates {

  constructor(private states:States) {
  }

  columnsUpdates = this.states.query.context.fireOnStateChange(this.states.table.columns, 'Query loaded');

  hierarchyUpdates = this.states.query.context.fireOnStateChange(this.states.table.hierarchies, 'Query loaded');

  relationUpdates = this.states.query.context.fireOnStateChange(this.states.table.relationColumns, 'Query loaded');
}


const ctx = createNewContext();
const states = ctx.create(States);

opServicesModule.value('states', states);
