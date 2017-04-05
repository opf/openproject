import {Component, createNewContext, input, inputStateCache} from "reactivestates";
import {Subject} from "rxjs";
import {opServicesModule} from "../angular-modules";
import {whenDebugging} from "../helpers/debug_output";
import {MultiState, State} from "../helpers/reactive-fassade";
import {QueryFormResource} from "./api/api-v3/hal-resources/query-form-resource.service";
import {QueryResource} from "./api/api-v3/hal-resources/query-resource.service";
import {SchemaResource} from "./api/api-v3/hal-resources/schema-resource.service";
import {TypeResource} from "./api/api-v3/hal-resources/type-resource.service";
import {WorkPackageResource} from "./api/api-v3/hal-resources/work-package-resource.service";
import {GroupObject, WorkPackageCollectionResource} from "./api/api-v3/hal-resources/wp-collection-resource.service";
import {WorkPackageEditForm} from "./wp-edit-form/work-package-edit-form";
import {WorkPackageTable} from "./wp-fast-table/wp-fast-table";
import {WorkPackageTableColumns} from "./wp-fast-table/wp-table-columns";
import {WorkPackageTableFilters} from "./wp-fast-table/wp-table-filters";
import {WorkPackageTableGroupBy} from "./wp-fast-table/wp-table-group-by";
import {WorkPackageTablePagination} from "./wp-fast-table/wp-table-pagination";
import {WorkPackageTableSortBy} from "./wp-fast-table/wp-table-sort-by";
import {WorkPackageTableSum} from "./wp-fast-table/wp-table-sum";
import {WPTableHierarchyState, WPTableRowSelectionState} from "./wp-fast-table/wp-table.interfaces";

export class States extends Component {

  /* /api/v3/work_packages */
  workPackages = inputStateCache<WorkPackageResource>();

  /* /api/v3/schemas */
  schemas = inputStateCache<SchemaResource>();

  /* /api/v3/types */
  types = inputStateCache<TypeResource>();

  // Work package table states
  table = new TableState();

  // Current focused work package (e.g, row preselected for details button)
  focusedWorkPackage = input<string>();

  // Open editing forms
  editing = new MultiState<WorkPackageEditForm>();

}

export class TableState {
  // the query associated with the table
  query = new State<QueryResource>();
  // the results associated with the table
  results = new State<WorkPackageCollectionResource>();
  // the query form associated with the table
  form = new State<QueryFormResource>();
  // Set of work package IDs in strict order of appearance
  rows = new State<WorkPackageResource[]>();
  // all groups returned as results
  groups = new State<GroupObject[]>();
  // Set of columns in strict order of appearance
  columns = new State<WorkPackageTableColumns>();
  // Set of filters
  filters = new State<WorkPackageTableFilters>();
  // Active and available sort by
  sortBy = new State<WorkPackageTableSortBy>();
  // Active and available group by
  groupBy = new State<WorkPackageTableGroupBy>();
  // is query summed
  sum = new State<WorkPackageTableSum>();
  // pagination information
  pagination = new State<WorkPackageTablePagination>();
  // Table row selection state
  selection = new State<WPTableRowSelectionState>();
  // Current state of collapsed groups (if any)
  collapsedGroups = new State<{[identifier:string]: boolean}>();
  // Hierarchies of table
  hierarchies = new State<WPTableHierarchyState>();
  // State to be updated when the table is up to date
  rendered = new State<WorkPackageTable>();
  // State to determine timeline visibility
  timelineVisible = new State<boolean>();
  // Subject used to unregister all listeners of states above.
  stopAllSubscriptions = new Subject();
}


const ctx = createNewContext();
const states = ctx.create(States);

whenDebugging(() => {
  states.enableLog(true);
});

opServicesModule.value('states', states);
