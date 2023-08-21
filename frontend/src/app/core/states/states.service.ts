import {
  InputState,
  multiInput,
  MultiInputState,
  StatesGroup,
} from '@openproject/reactivestates';
import { Subject } from 'rxjs';
import { TypeResource } from 'core-app/features/hal/resources/type-resource';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { VersionResource } from 'core-app/features/hal/resources/version-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { PlaceholderUserResource } from 'core-app/features/hal/resources/placeholder-user-resource';
import { RoleResource } from 'core-app/features/hal/resources/role-resource';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { PostResource } from 'core-app/features/hal/resources/post-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';

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
  timeEntries = multiInput<TimeEntryResource>();

  /* /api/v3/versions */
  versions = multiInput<VersionResource>();

  /* /api/v3/users */
  users = multiInput<UserResource>();

  /* /api/v3/placeholder_users */
  placeholderUsers = multiInput<PlaceholderUserResource>();

  /* /api/v3/roles */
  roles = multiInput<RoleResource>();

  // Global events to isolated changes
  changes = {
    // Global subject on changes to the given query ID
    queries: new Subject(),
  };

  // Additional state map that can be dynamically registered.
  additional:{ [id:string]:MultiInputState<unknown> } = {};

  forType<T>(stateName:string):MultiInputState<T> {
    let state = (this as any)[stateName] || this.additional[stateName];

    if (!state) {
      state = this.additional[stateName] = multiInput<T>();
    }

    return state;
  }

  forResource<T extends HalResource = HalResource>(resource:T):InputState<T>|undefined {
    const stateName = `${_.camelCase(resource._type)}s`;
    const state = this.forType<T>(stateName);

    return state && state.get(resource.id!);
  }

  public add(name:string, state:MultiInputState<HalResource>) {
    this.additional[name] = state;
  }
}
