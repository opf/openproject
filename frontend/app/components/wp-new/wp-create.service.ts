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

import {wpServicesModule} from '../../angular-modules';
import {ApiWorkPackagesService} from '../api/api-work-packages/api-work-packages.service';
import {HalResource} from '../api/api-v3/hal-resources/hal-resource.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {Observable, Subject} from 'rxjs';
import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from '../api/api-v3/hal-resources/work-package-resource.service';
import {input, State} from 'reactivestates';
import {WorkPackageEditingService} from '../wp-edit-form/work-package-editing-service';
import {WorkPackageChangeset} from '../wp-edit-form/work-package-changeset';

export class WorkPackageCreateService {
  protected form:ng.IPromise<HalResource>;

  // Allow callbacks to happen on newly created work packages
  protected newWorkPackageCreatedSubject = new Subject<WorkPackageResourceInterface>();

  constructor(protected $q:ng.IQService,
              protected wpCacheService:WorkPackageCacheService,
              protected apiWorkPackages:ApiWorkPackagesService) {
  }

  public newWorkPackageCreated(wp:WorkPackageResourceInterface) {
    this.newWorkPackageCreatedSubject.next(wp);
  }

  public onNewWorkPackage():Observable<WorkPackageResourceInterface> {
    return this.newWorkPackageCreatedSubject.asObservable();
  }

  public createNewWorkPackage(projectIdentifier:string) {
    return this.getEmptyForm(projectIdentifier).then(form => {
      return this.fromCreateForm(form);
    });
  }

  public createNewTypedWorkPackage(projectIdentifier:string, type:number) {
    return this.apiWorkPackages.typedCreateForm(type, projectIdentifier).then(form => {
      return this.fromCreateForm(form);
    });
  }

  public fromCreateForm(form:any) {
    var wp = new WorkPackageResource(form.payload.$plain(), true) as any;
    wp.initializeNewResource(form);

    return new WorkPackageChangeset(wp, form);
  }

  /**
   * Create a copy resource from other and the new work package form
   * @param otherForm The work package form of another work package
   * @param form Work Package create form
   */
  public copyFrom(otherForm:any, form:any) {
    var wp = new WorkPackageResource(otherForm.payload.$plain(), true) as any;

    // Override values from form payload
    wp.lockVersion = form.payload.lockVersion;

    wp.initializeNewResource(form);

    return new WorkPackageChangeset(wp, form);
  }

  public copyWorkPackage(copyFromForm:any, projectIdentifier?:string) {
    var request = copyFromForm.payload.$source;

    return this.apiWorkPackages.emptyCreateForm(request, projectIdentifier).then(form => {
      return this.copyFrom(copyFromForm, form);
    });
  }

  public getEmptyForm(projectIdentifier:string):ng.IPromise<HalResource> {
    if (!this.form) {
      this.form = this.apiWorkPackages.emptyCreateForm({}, projectIdentifier);
    }

    return this.form;
  }
}

wpServicesModule.service('wpCreate', WorkPackageCreateService);
