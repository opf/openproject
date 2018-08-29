//-- copyright
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
//++

import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {States} from '../../states.service';
import {buildApiV3Filter} from '../api-v3/api-v3-filter-builder';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {Inject, Injectable} from '@angular/core';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';

@Injectable()
export class ApiWorkPackagesService {
  constructor(protected halResourceService:HalResourceService,
              protected pathHelper:PathHelperService,
              protected states:States) {
  }

  /**
   * Loads a WorkPackage.
   *
   * @param id The ID of the WorkPackage.
   * @param force Bypass any cached value?
   * @returns {IPromise<any>|IPromise<WorkPackageResource>} A promise for the WorkPackage.
   */
  public loadWorkPackageById(id:string, force = false) {
    const url = this.pathHelper.api.v3.work_packages.id(id).toString();

    return this.halResourceService.get<WorkPackageResource>(url).toPromise();
  }

  /**
   * Loads the work packages collection for the given work package IDs.
   * Returns a WP Collection with schemas and results embedded.
   *
   * @param ids
   * @return {WorkPackageCollectionResource[]}
   */
  public loadWorkPackagesCollectionsFor(ids:string[]):Promise<WorkPackageCollectionResource[]> {
    return this.halResourceService.getAllPaginated(
      this.pathHelper.api.v3.work_packages.toString(),
      ids.length,
      {
        filters: buildApiV3Filter('id', '=', ids).toJson(),
      }
    ) as any; // WorkPackageCollectionResource does not satisfy constraint HalResource[]
  }

  /**
   * Returns a promise to post `/api/v3/work_packages/form`.
   *
   * @returns An empty work package form resource.
   */
  public emptyCreateForm(request:any, projectIdentifier?:string|null):Promise<HalResource> {
    return this.halResourceService
      .post<HalResource>(this.workPackagesFormPath(projectIdentifier), request)
      .toPromise();
  }

  /**
   * Returns a promise to post `/api/v3/work_packages/form` where the
   * type has already been set to the one provided.
   *
   * @param typeId: The id of the type to initialize the form with
   * @param projectIdentifier: The project to which the work package is initialized
   * @returns An empty work package form resource.
   */
  public typedCreateForm(typeId:number, projectIdentifier?:string):Promise<HalResource> {

    const typeUrl = this.pathHelper.api.v3.types.id(typeId).toString();
    const request = { _links: { type: { href: typeUrl } } };

    return this.halResourceService
      .post<HalResource>(this.workPackagesFormPath(projectIdentifier), request)
      .toPromise();
  }

  /**
   * Create a work package from a form payload
   *
   * @param payload
   * @return {Promise<WorkPackageResource>}
   */
  public createWorkPackage(payload:any):Promise<WorkPackageResource> {
    return this.halResourceService
      .post<WorkPackageResource>(this.pathHelper.api.v3.work_packages.path, payload)
      .toPromise();
  }

  private workPackagesFormPath(projectIdentifier?:string|null):string {
    if (projectIdentifier) {
      return this.pathHelper.api.v3.projects.id(projectIdentifier).work_packages.form.toString();
    } else {
      return this.pathHelper.api.v3.work_packages.form.toString();
    }
  }
}
