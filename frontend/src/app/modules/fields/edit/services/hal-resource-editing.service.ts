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
import {combine, deriveRaw, InputState, multiInput, MultiInputState, State, StatesGroup} from 'reactivestates';
import {map} from 'rxjs/operators';
import {Injectable, Injector} from '@angular/core';
import {WorkPackageChangeset} from "core-components/wp-edit/work-package-changeset";
import {SchemaCacheService} from "core-components/schemas/schema-cache.service";
import {Subject} from "rxjs";
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {ChangeMap} from "core-app/modules/fields/changeset/changeset";
import {ResourceChangeset} from "core-app/modules/fields/changeset/resource-changeset";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {StateCacheService} from "core-components/states/state-cache.service";

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
        this.wasNew = change.pristineResource.isNew;
        this.resource = saved;
        this.changes = change.changes;
    }
}

export interface ResourceChangesetClass {
    new(...args:any[]):ResourceChangeset
}

@Injectable()
export class HalResourceEditingService<V extends HalResource = HalResource, T extends ResourceChangeset<V> = ResourceChangeset<V>> extends StateCacheService<T> {

    /** Committed / saved changes to work packages observable */
    public comittedChanges = new Subject<ResourceChangesetCommit<V>>();

    /** State group of changes to wrap */
    private stateGroup = new ChangesetStates();

    public changesets:{[type:string]:ResourceChangesetClass} = {};

    constructor(readonly injector:Injector,
                readonly schemaCache:SchemaCacheService) {
        super();
    }

    public async save(change:T):Promise<ResourceChangesetCommit<V>> {
        change.inFlight = true;

        // Form the payload we're going to save
        const [form, payload] = await change.buildRequestPayload();
        // Reject errors when occurring in form validation
        const errors = form.getErrors();
        if (errors !== null) {
            change.inFlight = false;
            throw(errors);
        }

        const savedResource = await change.pristineResource.$links.updateImmediately(payload);

        // Ensure the schema is loaded before updating
        // ToDo: await this.schemaCache.ensureLoaded(savedResource);

        // Initialize any potentially new HAL values
        savedResource.retainFrom(change.pristineResource);

        this.onSaved(savedResource);

        change.inFlight = false;

        // Complete the change
        return this.complete(change, savedResource);
    }

    /**
     * Mark the given change as completed, notify changes
     * and reset it.
     */
    private complete(change:T, saved:V):ResourceChangesetCommit<V> {
        const commit = new ResourceChangesetCommit<V>(change, saved);
        this.comittedChanges.next(commit);
        this.reset(change);

        return commit;
    }

    /**
     * Reset the given change, either due to cancelling or successful submission.
     * @param change
     */
    public reset(change:T) {
        change.clear();
        this.clearSome(change.href);
    }

    /**
     * Create a new changeset for the given work package, discarding any previous changeset that might exist
     * @param resource
     * @param form
     */
    public edit(resource:V, form?:FormResource):T {
        const state = this.multiState.get(resource.href!);
        const changeset = this.newChangeset(resource, state, form)

        state.putValue(changeset);
        return changeset;
    }

    protected newChangeset(resource:V, state:InputState<T>, form?:FormResource):T {
        const cls = this.changesets[resource._type] || ResourceChangeset;
        return new cls(resource, state, form) as T;
    }

    /**
     * Start or continue editing the work package with a given edit context
     * @param {workPackage} Work package to edit
     * @param {form:FormResource} Initialize with an existing form
     * @return {WorkPackageChangeset} Change object to work on
     */
    public changeFor(fallback:V):T {
        const state = this.multiState.get(fallback.href!);
        let resource = fallback;
        if (fallback.state) {
            resource = fallback.state.getValueOr(fallback);
        }
        let changeset = state.value;

        // If there is no changeset, or
        // If there is an empty one for a older work package reference
        // build a new changeset
        if (changeset && !changeset.isEmpty()) {
           return changeset;
        }
        if (!changeset || resource.hasOwnProperty('lockVersion') && changeset.pristineResource.lockVersion < resource.lockVersion) {
            return this.edit(resource);
        }

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
     * @return {State<WorkPackageResource>}
     */
    public temporaryEditResource(resource:V):State<V> {
        const combined = combine(resource.state!, this.state(resource.href!) as State<T>);

        return deriveRaw(combined,
            ($) => $
                .pipe(
                    map(([resource, change]) => {
                        if (resource && change && !change.isEmpty()) {
                            return change.projectedResource;
                        } else {
                            return resource;
                        }
                    })
                )
        );
    }

    public stopEditing(href:string) {
        this.multiState.get(href).clear();
    }

    protected load(href:string):Promise<T> {
        // ToDo: Correct return object
       return Promise.reject('Loading not implemented yet.') as any;
    }

    protected onSaved(saved:HalResource) {
        // ToDo: Move into HalEvents
        /* this.wpActivity.clear(saved.id);

        // If there is a parent, its view has to be updated as well
        if (saved.parent) {
            this.wpCacheService.loadWorkPackage(saved.parent.id.toString(), true);
        }
        this.wpCacheService.updateWorkPackage(saved);
        */
    }

    protected loadAll(hrefs:string[]) {
        return Promise.all(hrefs.map(href => this.load(href))) as any;
    }

    protected get multiState():MultiInputState<T> {
        return this.stateGroup.changesets as MultiInputState<T>;
    }

    addChangeset(name:string, changeset:ResourceChangesetClass) {
        this.changesets[name] = changeset;
    }
}

