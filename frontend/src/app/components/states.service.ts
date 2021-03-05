import { ProjectResource } from 'core-app/modules/hal/resources/project-resource';
import { SchemaResource } from 'core-app/modules/hal/resources/schema-resource';
import { TypeResource } from 'core-app/modules/hal/resources/type-resource';
import { RoleResource } from 'core-app/modules/hal/resources/role-resource';
import { UserResource } from 'core-app/modules/hal/resources/user-resource';
import { PlaceholderUserResource } from 'core-app/modules/hal/resources/placeholder-user-resource';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { input, InputState, multiInput, MultiInputState, StatesGroup } from 'reactivestates';
import { QueryColumn } from './wp-query/query-column';
import { PostResource } from 'core-app/modules/hal/resources/post-resource';
import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { StatusResource } from "core-app/modules/hal/resources/status-resource";
import { QueryFilterInstanceSchemaResource } from "core-app/modules/hal/resources/query-filter-instance-schema-resource";
import { Subject } from "rxjs";
import { QuerySortByResource } from "core-app/modules/hal/resources/query-sort-by-resource";
import { QueryGroupByResource } from "core-app/modules/hal/resources/query-group-by-resource";
import { VersionResource } from "core-app/modules/hal/resources/version-resource";
import { WorkPackageDisplayRepresentationValue } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import { TimeEntryResource } from "core-app/modules/hal/resources/time-entry-resource";

export class States extends StatesGroup {
  name = 'MainStore';

  /* /api/v3/projects */
  projects:MultiInputState<ProjectResource> = multiInput<ProjectResource>();

  /* /api/v3/work_packages */
  workPackages = multiInput<WorkPackageResource>();

  /* /api/v3/wiki_pages */
  posts = multiInput<PostResource>();

  /* /api/v3/schemas */
  schemas = multiInput<SchemaResource>();

  /* /api/v3/types */
  types = multiInput<TypeResource>();

  /* /api/v3/statuses */
  statuses = multiInput<StatusResource>();

  /* /api/v3/time_entries */
  timeEntries:MultiInputState<TimeEntryResource> = multiInput<TimeEntryResource>();

  /* /api/v3/versions */
  versions = multiInput<VersionResource>();

  /* /api/v3/users */
  users = multiInput<UserResource>();

  /* /api/v3/placeholder_users */
  placeholderUsers = multiInput<PlaceholderUserResource>();

  /* /api/v3/roles */
  roles = multiInput<RoleResource>();


  // Work Package query states
  queries = new QueryAvailableDataStates();

  // Global events to isolated changes
  changes = new GlobalStateChanges();

  // Additional state map that can be dynamically registered.
  additional:{ [id:string]:MultiInputState<unknown> } = {};

  forType<T>(stateName:string):MultiInputState<T> {
    let state = (this as any)[stateName] || this.additional[stateName];

    if (!state) {
      state = this.additional[stateName] = multiInput<T>();
    }

    return state as any;
  }

  forResource<T extends HalResource = HalResource>(resource:T):InputState<T>|undefined {
    const stateName = _.camelCase(resource._type) + 's';
    const state = this.forType<T>(stateName);

    return state && state.get(resource.id!);
  }

  public add(name:string, state:MultiInputState<HalResource>) {
    this.additional[name] = state;
  }
}

export class GlobalStateChanges {
  // Global subject on changes to the given query ID
  queries = new Subject();
}

export class QueryAvailableDataStates {
  // Available columns
  columns = input<QueryColumn[]>();

  // Available SortBy Columns
  sortBy = input<QuerySortByResource[]>();

  // Available GroupBy columns
  groupBy = input<QueryGroupByResource[]>();

  // Available filter schemas (derived from their schema)
  filters = input<QueryFilterInstanceSchemaResource[]>();

  // Display of the WP results
  displayRepresentation = input<WorkPackageDisplayRepresentationValue|null>();
}
