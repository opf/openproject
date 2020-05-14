// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {Injectable, Injector} from '@angular/core';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {Observable, Subject} from 'rxjs';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {HookService} from 'core-app/modules/plugins/hook-service';
import {WorkPackageFilterValues} from "core-components/wp-edit-form/work-package-filter-values";

import {
  HalResourceEditingService,
  ResourceChangesetCommit
} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {WorkPackageChangeset} from "core-components/wp-edit/work-package-changeset";
import {filter} from "rxjs/operators";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageDmService} from "core-app/modules/hal/dm-services/work-package-dm.service";
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {HalEventsService} from "core-app/modules/hal/services/hal-events.service";
import {AuthorisationService} from "core-app/modules/common/model-auth/model-auth.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

export const newWorkPackageHref = '/api/v3/work_packages/new';

@Injectable()
export class WorkPackageCreateService extends UntilDestroyedMixin {
  protected form:Promise<FormResource>|undefined;

  // Allow callbacks to happen on newly created work packages
  protected newWorkPackageCreatedSubject = new Subject<WorkPackageResource>();

  constructor(protected injector:Injector,
              protected hooks:HookService,
              protected wpCacheService:WorkPackageCacheService,
              protected halResourceService:HalResourceService,
              protected querySpace:IsolatedQuerySpace,
              protected authorisationService:AuthorisationService,
              protected halEditing:HalResourceEditingService,
              protected workPackageDmService:WorkPackageDmService,
              protected halEvents:HalEventsService) {
    super();

    this.halEditing
      .comittedChanges
      .pipe(
        this.untilDestroyed(),
        filter(commit => commit.resource._type === 'WorkPackage' && commit.wasNew)
      )
      .subscribe((commit:ResourceChangesetCommit<WorkPackageResource>) => {
        this.newWorkPackageCreated(commit.resource);
      });

    this.halEditing
      .changes$(newWorkPackageHref)
      .pipe(
        this.untilDestroyed(),
        filter(changeset => !changeset)
      )
      .subscribe(() => {
        this.reset();
      });
  }

  protected newWorkPackageCreated(wp:WorkPackageResource) {
    this.reset();
    this.newWorkPackageCreatedSubject.next(wp);
  }

  public onNewWorkPackage():Observable<WorkPackageResource> {
    return this.newWorkPackageCreatedSubject.asObservable();
  }

  public createNewWorkPackage(projectIdentifier:string|undefined|null) {
    return this.getEmptyForm(projectIdentifier).then(form => {
      return this.fromCreateForm(form);
    });
  }

  public createNewTypedWorkPackage(projectIdentifier:string|undefined|null, type:number) {
    return this.workPackageDmService.typedCreateForm(type, projectIdentifier).then(form => {
      return this.fromCreateForm(form);
    });
  }

  public fromCreateForm(form:FormResource):WorkPackageChangeset {
    let wp = this.halResourceService.createHalResourceOfType<WorkPackageResource>('WorkPackage', form.payload.$plain());
    wp.initializeNewResource(form);

    const change = this.halEditing.edit<WorkPackageResource, WorkPackageChangeset>(wp, form);

    // Call work package initialization hook
    this.hooks.call('workPackageNewInitialization', change);

    return change;
  }

  public copyWorkPackage(copyFrom:WorkPackageChangeset) {
    let request = copyFrom.pristineResource.$source;

    // Ideally we would make an empty request before to get the create schema (cannot use the update schema of the source changeset)
    // to get all the writable attributes and only send those.
    // But as this would require an additional request, we don't.
    return this.workPackageDmService.emptyCreateForm(request).then(form => {
      let changeset = this.fromCreateForm(form);

      return changeset;
    });
  }

  /**
   * Create a copy resource from other and the new work package form
   * @param form Work Package create form
   */
  private copyFrom(form:FormResource) {
    //let wp = fromCreateForm(form);
    let wp = this.halResourceService.createHalResourceOfType<WorkPackageResource>('WorkPackage', form.payload.$plain());

    wp.initializeNewResource(form);

    return this.halEditing.edit(wp, form);
  }


  public getEmptyForm(projectIdentifier:string|null|undefined):Promise<FormResource> {
    if (!this.form) {
      this.form = this.workPackageDmService.emptyCreateForm({}, projectIdentifier);
    }

    return this.form;
  }

  public cancelCreation() {
    this.halEditing.stopEditing({ href: newWorkPackageHref });
    this.reset();
  }

  public changesetUpdates$() {
    return this
      .halEditing
      .state(newWorkPackageHref)
      .values$();
  }

  public createOrContinueWorkPackage(projectIdentifier:string|null|undefined, type?:number) {
    let changePromise = this.continueExistingEdit(type);

    if (!changePromise) {
      changePromise = this.createNewWithDefaults(projectIdentifier, type);
    }

    return changePromise.then((change:WorkPackageChangeset) => {
      this.authorisationService.initModelAuth('work_package', change.pristineResource);
      this.halEditing.updateValue(newWorkPackageHref, change);
      this.wpCacheService.updateWorkPackage(change.pristineResource);

      return change;
    });
  }

  protected reset() {
    this.wpCacheService.clearSome('new');
    this.form = undefined;
  }

  protected continueExistingEdit(type?:number) {
    const change = this.halEditing.state(newWorkPackageHref).value as WorkPackageChangeset;
    if (change !== undefined) {
      const changeType = change.projectedResource.type;

      const hasChanges = !change.isEmpty();
      const typeEmpty = !changeType && !type;
      const typeMatches = type && changeType && changeType.idFromLink === type.toString();

      if (hasChanges && (typeEmpty || typeMatches)) {
        return Promise.resolve(change);
      }
    }

    return null;
  }

  protected createNewWithDefaults(projectIdentifier:string|null|undefined, type?:number) {
    let changePromise = null;

    if (type) {
      changePromise = this.createNewTypedWorkPackage(projectIdentifier, type);
    } else {
      changePromise = this.createNewWorkPackage(projectIdentifier);
    }

    return changePromise.then((change:WorkPackageChangeset) => {
      if (!change) {
        throw 'No new work package was created';
      }

      let except:string[] = [];

      if (type) {
        except = ['type'];
      }

      this.applyDefaults(change, change.projectedResource, except);

      return change;
    });
  }

  /**
   * Apply values to the work package from the current set of filters
   *
   * @param changeset
   * @param wp
   * @param except
   */
  private applyDefaults(change:WorkPackageChangeset, wp:WorkPackageResource, except:string[]) {
    // Not using WorkPackageViewFiltersService here as the embedded table does not load the form
    // which will result in that service having empty current filters.
    let query = this.querySpace.query.value;

    if (query) {
      const filter = new WorkPackageFilterValues(this.injector, change, query.filters, except);
      filter.applyDefaultsFromFilters();
    }
  }
}
