import {WPFocusState} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {combine, derive, input, multiInput, StatesGroup} from 'reactivestates';
import {mapTo} from 'rxjs/operators';
import {opServicesModule} from '../angular-modules';
import {QueryFormResource} from './api/api-v3/hal-resources/query-form-resource.service';
import {QueryGroupByResource} from './api/api-v3/hal-resources/query-group-by-resource.service';
import {QueryResource} from './api/api-v3/hal-resources/query-resource.service';
import {QuerySortByResource} from './api/api-v3/hal-resources/query-sort-by-resource.service';
import {SchemaResource} from './api/api-v3/hal-resources/schema-resource.service';
import {TypeResource} from './api/api-v3/hal-resources/type-resource.service';
import {WorkPackageResourceInterface} from './api/api-v3/hal-resources/work-package-resource.service';
import {SwitchState} from './states/switch-state';
import {QueryColumn} from './wp-query/query-column';

export class States extends StatesGroup {

  name = 'MainStore';

  /* /api/v3/work_packages */
  workPackages = multiInput<WorkPackageResourceInterface>();

  /* /api/v3/schemas */
  schemas = multiInput<SchemaResource>();

  /* /api/v3/types */
  types = multiInput<TypeResource>();

  // Work Package query states
  query = new QueryStates();

  // Current focused work package (e.g, row preselected for details button)
  focusedWorkPackage = input<WPFocusState>();

}

export class QueryStates {

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

opServicesModule.value('states', new States());
