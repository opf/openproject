// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {combine, deriveRaw, multiInput, State, StatesGroup} from 'reactivestates';
import {map} from 'rxjs/operators';
import {wpServicesModule} from '../../angular-modules';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {StateCacheService} from '../states/state-cache.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageChangeset} from './work-package-changeset';
import {WorkPackageEditContext} from './work-package-edit-context';
import {WorkPackageEditForm} from './work-package-edit-form';

class WPChangesetStates extends StatesGroup {
  name = 'WP-Changesets';

  changesets = multiInput<WorkPackageChangeset>();

  constructor() {
    super();
    this.initializeMembers();
  }
}

export class WorkPackageEditingService extends StateCacheService<WorkPackageChangeset> {

  private stateGroup:WPChangesetStates;

  constructor(public wpCacheService:WorkPackageCacheService) {
    super();
    this.stateGroup = new WPChangesetStates();
  }

  /**
   * Start or continue editing the work package with a given edit context
   * @param {string} workPackageId
   * @param {WorkPackageEditContext} editContext
   * @param {boolean} editAll
   * @return {WorkPackageChangeset} changeset or null if the associated work package id does not exist
   */
  public changesetFor(oldReference:WorkPackageResourceInterface):WorkPackageChangeset {
    const wpId = oldReference.id;
    const workPackage = this.wpCacheService.state(wpId).getValueOr(oldReference);
    const state = this.multiState.get(wpId);

    if (state.isPristine()) {
      state.putValue(new WorkPackageChangeset(workPackage));
    }

    const changeset = state.value!;
    changeset.workPackage = workPackage;

    return changeset;
  }

  /**
   * Get a temporary view on the resource being edited.
   * IF there is a changeset:
   *   - Merge the changeset, including its form, into the work package resource
   * IF there is no changeset:
   *   - The work package itself is returned.
   *
   *  This resource has a read only index signature to make it clear it is NOT
   *  meant for editing.
   *
   * @return {State<WorkPackageResourceInterface>}
   */
  public temporaryEditResource(id:string):State<WorkPackageResourceInterface> {
    const combined = combine(this.wpCacheService.state(id), this.state(id));

    return deriveRaw(combined,
      ($) => $
        .pipe(
          map(([wp, changeset]) => {
            if (wp && changeset && changeset.resource) {
              return changeset.resource;
            } else {
              return wp;
            }
          })
        )
    );
  }

  public stopEditing(workPackageId:string) {
    const state = this.multiState.get(workPackageId);
    if (state && state.value) {
      state.value.clear();
    }
  }

  public async saveChanges(workPackageId:string):Promise<WorkPackageResourceInterface> {
    const state = this.state(workPackageId);

    if (state.hasValue()) {
      const changeset = state.value!;
      return new WorkPackageEditForm(changeset.workPackage).submit();
    }

    return Promise.reject('No changeset present') as any;
  }

  protected async load(id:string) {
    return this.wpCacheService.require(id)
      .then((wp:WorkPackageResourceInterface) => {
        return new WorkPackageChangeset(wp);
      });
  }

  protected loadAll(ids:string[]) {
    return Promise.all(ids.map(async id => this.load(id))) as any;
  }

  protected get multiState() {
    return this.stateGroup.changesets;
  }
}

wpServicesModule.service('wpEditing', WorkPackageEditingService);
