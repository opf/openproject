import {Component, createNewContext, input, inputStateCache} from "reactivestates";
import {Subject} from "rxjs";
import {opServicesModule} from "../angular-modules";
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
import {WPTableRowSelectionState} from "./wp-fast-table/wp-table.interfaces";
import {whenDebugging} from "../helpers/debug_output";
import {WorkPackageTableHierarchies} from "./wp-fast-table/wp-table-hierarchies";
import {WorkPackageTableTimelineState} from "./wp-fast-table/wp-table-timeline";
import {TableRenderResult} from './wp-fast-table/builders/modes/table-render-pass';

export class States extends Component {

  name = "MainStore";
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
  editing = inputStateCache<WorkPackageEditForm>();

}

export class TableState {

  name = "TableStore";

  // the query associated with the table
  query = input<QueryResource>();
  // the results associated with the table
  results = input<WorkPackageCollectionResource>();
  // the query form associated with the table
  form = input<QueryFormResource>();
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
  rendered = input<TableRenderResult>();
  // State to determine timeline visibility
  timelineVisible = input<WorkPackageTableTimelineState>();
  // Subject used to unregister all listeners of states above.
  stopAllSubscriptions = new Subject();
  // Fire when table refresh is required
  refreshRequired = input<boolean>();
}


const ctx = createNewContext();
const states = ctx.create(States);

whenDebugging(() => {
  states.enableLog(true);
});

opServicesModule.value('states', states);
