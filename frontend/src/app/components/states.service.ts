import {ProjectResource} from 'core-app/modules/hal/resources/project-resource';
import {QueryGroupByResource} from 'core-app/modules/hal/resources/query-group-by-resource';
import {QuerySortByResource} from 'core-app/modules/hal/resources/query-sort-by-resource';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {TypeResource} from 'core-app/modules/hal/resources/type-resource';
import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WPFocusState} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {input, InputState, multiInput, MultiInputState, StatesGroup} from 'reactivestates';
import {QueryColumn} from './wp-query/query-column';
import {WikiPageResource} from 'core-app/modules/hal/resources/wiki-page-resource';
import {PostResource} from 'core-app/modules/hal/resources/post-resource';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {StatusResource} from "core-app/modules/hal/resources/status-resource";

export class States extends StatesGroup {
  [key:string]:any;

  name = 'MainStore';

  /* /api/v3/projects */
  projects:MultiInputState<ProjectResource> = multiInput<ProjectResource>();

  /* /api/v3/work_packages */
  workPackages = multiInput<WorkPackageResource>();

  /* /api/v3/wiki_pages */
  wikiPages = multiInput<WikiPageResource>();

  /* /api/v3/wiki_pages */
  posts = multiInput<PostResource>();

  /* /api/v3/schemas */
  schemas = multiInput<SchemaResource>();

  /* /api/v3/types */
  types = multiInput<TypeResource>();

  /* /api/v3/types */
  statuses = multiInput<StatusResource>();

  /* /api/v3/users */
  users = multiInput<UserResource>();

  // Work Package query states
  queries = new QueryAvailableDataStates();

  // Current focused work package (e.g, row preselected for details button)
  focusedWorkPackage:InputState<WPFocusState> = input<WPFocusState>();

  forResource(resource:HalResource):InputState<HalResource> {
    let stateName = _.camelCase(resource._type) + 's';

    return this[stateName].get(resource.id);
  }

  public add(name:string, state:MultiInputState<HalResource>) {
    this[name] = state;
  }
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
