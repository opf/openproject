//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { camelCase } from 'lodash-es';
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
  additional:Record<string, MultiInputState<unknown>> = {};

  forType<T>(stateName:string):MultiInputState<T> {
    let state = (this as any)[stateName] || this.additional[stateName];

    if (!state) {
      state = this.additional[stateName] = multiInput<T>();
    }

    return state;
  }

  forResource<T extends HalResource = HalResource>(resource:T):InputState<T>|undefined {
    const stateName = `${camelCase(resource._type)}s`;
    const state = this.forType<T>(stateName);

    return state && state.get(resource.id!);
  }

  public add(name:string, state:MultiInputState<HalResource>) {
    this.additional[name] = state;
  }
}
