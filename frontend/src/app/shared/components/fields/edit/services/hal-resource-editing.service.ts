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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  combine, deriveRaw, InputState, multiInput, State, StatesGroup,
} from '@openproject/reactivestates';
import { filter, map } from 'rxjs/operators';
import { Injectable, Injector } from '@angular/core';
import { Subject } from 'rxjs';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { ChangeMap } from 'core-app/shared/components/fields/changeset/changeset';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HookService } from 'core-app/features/plugins/hook-service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { StateCacheService } from 'core-app/core/apiv3/cache/state-cache.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';

class ChangesetStates extends StatesGroup {
  name = 'Changesets';

  changesets = multiInput<ResourceChangeset>();

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
export class ResourceChangesetCommit<T extends HalResource = HalResource> {
  /**
   * The work package id of the change
   * (This is the new work package ID if +wasNew+ is true.
   */
  public readonly id:string;

  /**
   * The resulting, saved work package.
   */
  public readonly resource:T;

  /** Whether the commit saved an initial work package */
  public readonly wasNew:boolean = false;

  /** The previous changes */
  public readonly changes:ChangeMap;

  /**
   * Create a change commit from the change object
   * @param change The change object that resulted in the save
   * @param saved The returned work package
   */
  constructor(change:ResourceChangeset<T>, saved:T) {
    this.id = saved.id!.toString();
    this.wasNew = isNewResource(change.pristineResource);
    this.resource = saved;
    this.changes = change.changeMap;
  }
}

export interface ResourceChangesetClass {
  new(...args:any[]):ResourceChangeset;
}

@Injectable()
export class HalResourceEditingService extends StateCacheService<ResourceChangeset> {
  /** Committed / saved changes to work packages observable */
  public committedChanges = new Subject<ResourceChangesetCommit>();

  constructor(protected readonly injector:Injector,
    protected readonly halEvents:HalEventsService,
    protected readonly hook:HookService) {
    super(new ChangesetStates().changesets);
  }

  public async save<V extends HalResource, T extends ResourceChangeset<V>>(change:T):Promise<ResourceChangesetCommit<V>> {
    // Form the payload we're going to save
    const payload = await change.buildRequestPayload();
    const savedResource = await change.pristineResource.$links.updateImmediately(payload);

    // Initialize any potentially new HAL values
    savedResource.retainFrom(change.pristineResource);

    await this.onSaved(savedResource);

    // Complete the change
    return this.complete(change, savedResource);
  }

  /**
   * Mark the given change as completed, notify changes
   * and reset it.
   */
  private complete<V extends HalResource, T extends ResourceChangeset<V>>(change:T, saved:V):ResourceChangesetCommit<V> {
    const commit = new ResourceChangesetCommit<V>(change, saved);
    this.committedChanges.next(commit);
    this.reset(change);

    const eventType = commit.wasNew ? 'created' : 'updated';
    this.halEvents.push(commit.resource, { eventType, commit });

    return commit;
  }

  /**
   * Reset the given change, either due to cancelling or successful submission.
   * @param change
   */
  public reset<V extends HalResource, T extends ResourceChangeset<V>>(change:T) {
    change.clear();
    this.clearSome(change.href);
  }

  /**
   * Returns the typed state value. Use this to get a changeset
   * for a subtype of ResourceChangeset<HalResource>.
   * @param resource
   */
  public typedState<V extends HalResource, T extends ResourceChangeset<V>>(resource:V):State<T> {
    return this.multiState.get(resource.href!) as InputState<T>;
  }

  /**
   * Create a new changeset for the given work package, discarding any previous changeset that might exist.
   *
   * @param resource
   * @param form
   *
   * @return The state for the created changeset
   */
  public edit<V extends HalResource, T extends ResourceChangeset<V>>(resource:V, form?:FormResource):T {
    const state = this.multiState.get(resource.href!) as InputState<T>;
    const changeset = this.newChangeset(resource, state, form);

    state.putValue(changeset);

    return changeset;
  }

  protected newChangeset<V extends HalResource, T extends ResourceChangeset<V>>(resource:V, state:InputState<T>, form?:FormResource):T {
    // we take the last registered group component which means that
    // plugins will have their say if they register for it.
    const cls = this.hook.call('halResourceChangesetClass', resource).pop() || ResourceChangeset;
    return new cls(resource, state, form) as T;
  }

  /**
   * Start or continue editing the work package with a given edit context
   * @param fallback Fallback resource to use
   * @return {ResourceChangeset} Change object to work on
   */
  public changeFor<V extends HalResource, T extends ResourceChangeset<V>>(fallback:V):T {
    const state = this.multiState.get(fallback.href!) as InputState<T>;
    let resource = fallback;
    if (fallback.state) {
      resource = fallback.state.getValueOr(fallback);
    }
    const changeset = state.value;

    // If there is no changeset, or
    // If there is an empty one for a older work package reference
    // build a new changeset
    if (changeset && !changeset.isEmpty()) {
      return changeset;
    }

    if (!changeset) {
      return this.edit<V, T>(resource);
    }

    if (resource.hasOwnProperty('lockVersion') && changeset.pristineResource.lockVersion < resource.lockVersion) {
      return this.edit<V, T>(resource);
    }

    changeset.updatePristineResource(resource);
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
   * @return {State<HalResource>}
   */
  public temporaryEditResource<V extends HalResource, T extends ResourceChangeset<V>>(resource:V):State<V> {
    const combined = combine(resource.state! as State<V>, this.typedState<V, T>(resource));

    return deriveRaw(combined,
      ($) => $
        .pipe(
          filter(([resource, _]) => !!resource),
          map(([resource, change]) => {
            if (change) {
              change.updatePristineResource(resource as V);
              return change.projectedResource;
            }

            return resource;
          }),
        ));
  }

  public stopEditing(resource:HalResource|{ href:string }) {
    this.multiState.get(resource.href!).clear();
  }

  protected onSaved(saved:HalResource):Promise<unknown> {
    if (saved.state) {
      return saved.push(saved);
    }

    return Promise.resolve();
  }
}
