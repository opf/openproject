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

import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {combine, deriveRaw, multiInput, MultiInputState, State, StatesGroup} from 'reactivestates';
import {map} from 'rxjs/operators';
import {StateCacheService} from '../states/state-cache.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {Injectable, Injector} from '@angular/core';
import {WorkPackagesActivityService} from "core-components/wp-single-view-tabs/activity-panel/wp-activity.service";
import {WorkPackageChange} from "core-components/wp-edit/work-package-change";
import {SchemaCacheService} from "core-components/schemas/schema-cache.service";
import {ChangeMap} from "core-components/wp-edit/changeset";
import {Subject} from "rxjs";
import {FormResource} from "core-app/modules/hal/resources/form-resource";

class WPChangesStates extends StatesGroup {
  name = 'WP-Changesets';

  changesets = multiInput<WorkPackageChange>();

  constructor() {
    super();
    this.initializeMembers();
  }
}

/**
 * Wrapper class for the saved change of a work package,
 * used to access the previous save and or previous state
 * of the work package (e.g., whether it was new).
 */
export class WorkPackageChangeCommit {
  /**
   * The work package id of the change
   * (This is the new work package ID if +wasNew+ is true.
   */
  public readonly id:string;

  /**
   * The resulting, saved work package.
   */
  public readonly workPackage:WorkPackageResource;

  /** Whether the commit saved an initial work package */
  public readonly wasNew:boolean = false;

  /** The previous changes */
  public readonly changes:ChangeMap;

  /**
   * Create a change commit from the change object
   * @param change The change object that resulted in the save
   * @param saved The returned work package
   */
  constructor(change:WorkPackageChange, saved:WorkPackageResource) {
    this.id = saved.id.toString();
    this.wasNew = change.base.isNew;
    this.workPackage = saved;
    this.changes = change.changes;
  }
}


@Injectable()
export class WorkPackageEditingService extends StateCacheService<WorkPackageChange> {

  /** Committed / saved changes to work packages observable */
  public comittedChanges = new Subject<WorkPackageChangeCommit>();

  /** State group of changes to wrap */
  private stateGroup = new WPChangesStates();

  constructor(readonly injector:Injector,
              readonly wpActivity:WorkPackagesActivityService,
              readonly schemaCache:SchemaCacheService,
              readonly wpCacheService:WorkPackageCacheService) {
    super();
  }

  public async save(change:WorkPackageChange):Promise<WorkPackageChangeCommit> {
    change.inFlight = true;

    // TODO remove? const wasNew = change.base.isNew;

    // Form the payload we're going to save
    const [form, payload] = await change.buildRequestPayload();
    // Reject errors when occurring in form validation
    const errors = form.getErrors();
    if (errors !== null) {
      throw(errors);
    }

    const savedWp = await change.base.$links.updateImmediately(payload);

    // Ensure the schema is loaded before updating
    await this.schemaCache.ensureLoaded(savedWp);

    // Initialize any potentially new HAL values
    savedWp.retainFrom(change.base);

    this.onSaved(savedWp);

    // Complete the change
    return this.complete(change, savedWp);
  }

  /**
   * Mark the given change as completed, notify changes
   * and reset it.
   */
  private complete(change:WorkPackageChange, saved:WorkPackageResource):WorkPackageChangeCommit {
    const commit = new WorkPackageChangeCommit(change, saved)
    this.comittedChanges.next(commit);
    this.reset(change);

    return commit;
  }

  /**
   * Reset the given change, either due to cancelling or successful submission.
   * @param change
   */
  public reset(change:WorkPackageChange) {
    change.clear();
    this.clearSome(change.workPackageId);
  }


  /**
   * Start or continue editing the work package with a given edit context
   * @param {workPackage} Work package to edit
   * @param {form:FormResource} Initialize with an existing form
   * @return {WorkPackageChange} Change object to work on
   */
  public changeFor(fallback:WorkPackageResource, form?:FormResource):WorkPackageChange {
    const state = this.multiState.get(fallback.id);
    const workPackage = this.wpCacheService.state(fallback.id).getValueOr(fallback);

    if (state.isPristine()) {
      state.putValue(new WorkPackageChange(workPackage, state, form));
    }

    const change = state.value!;
    change.base = workPackage;
    return change;
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
   * @return {State<WorkPackageResource>}
   */
  public temporaryEditResource(id:string):State<WorkPackageResource> {
    const combined = combine(this.wpCacheService.state(id), this.state(id));

    return deriveRaw(combined,
      ($) => $
        .pipe(
          map(([wp, change]) => {
            if (wp && change && !change.isEmpty) {
              return change.projectedWorkPackage;
            } else {
              return wp;
            }
          })
        )
    );
  }

  public stopEditing(workPackageId:string) {
    const state = this.multiState.get(workPackageId);
    const change:WorkPackageChange|undefined = state.value;
    if (change !== undefined) {
      change.clear();
    }
  }

  protected load(id:string):Promise<WorkPackageChange> {
    return this.wpCacheService.require(id)
      .then((wp:WorkPackageResource) => {
        return this.changeFor(wp);
      });
  }

  protected onSaved(saved:WorkPackageResource) {
    this.wpActivity.clear(saved.id);

    // If there is a parent, its view has to be updated as well
    if (saved.parent) {
      this.wpCacheService.loadWorkPackage(saved.parent.id.toString(), true);
    }
    this.wpCacheService.updateWorkPackage(saved);
  }

  protected loadAll(ids:string[]) {
    return Promise.all(ids.map(id => this.load(id))) as any;
  }

  protected get multiState():MultiInputState<WorkPackageChange> {
    return this.stateGroup.changesets;
  }
}

