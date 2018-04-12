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
import {opApiModule} from '../../../angular-modules';
import {States} from '../../states.service';
import {buildApiV3Filter} from '../api-v3/api-v3-filter-builder';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';

export class ApiWorkPackagesService {
  constructor(protected $q:ng.IQService,
              protected halRequest:HalResourceService,
              protected v3Path:any,
              protected states:States) {
  }

  /**
   * Loads a WorkPackage.
   *
   * @param id The ID of the WorkPackage.
   * @param force Bypass any cached value?
   * @returns {IPromise<any>|IPromise<WorkPackageResource>} A promise for the WorkPackage.
   */
  public async loadWorkPackageById(id:string, force = false) {
    const url = this.v3Path.wp({wp: id});

    return this.halRequest.get<WorkPackageResource>(url).toPromise();
  }

  /**
   * Loads the work packages collection for the given work package IDs.
   * Returns a WP Collection with schemas and results embedded.
   *
   * @param ids
   * @return {WorkPackageCollectionResource[]}
   */
  public loadWorkPackagesCollectionsFor(ids:string[]):Promise<WorkPackageCollectionResource[]> {
    return this.halRequest.getAllPaginated(
      this.v3Path.wps(),
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
  public emptyCreateForm(request:any, projectIdentifier?:string):Promise<HalResource> {
    return this.halRequest
      .post<HalResource>(this.v3Path.wp.form({ project: projectIdentifier }), request)
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

    const typeUrl = this.v3Path.types({type: typeId});
    const request = { _links: { type: { href: typeUrl } } };

    return this.halRequest
      .post<HalResource>(this.v3Path.wp.form({ project: projectIdentifier }), request)
      .toPromise();
  }

  /**
   * Returns a promise to GET `/api/v3/work_packages/available_projects`.
   */
  public availableProjects(projectIdentifier?:string):Promise<HalResource> {
    return this.halRequest
      .get<HalResource>(this.v3Path.wp.availableProjects({project: projectIdentifier}))
      .toPromise();
  }

  /**
   * Create a work package from a form payload
   *
   * @param payload
   * @return {Promise<WorkPackageResource>}
   */
  public createWorkPackage(payload:any):Promise<WorkPackageResource> {
    return this.halRequest
      .post<WorkPackageResource>(this.v3Path.wps(), payload)
      .toPromise();
  }
}

opApiModule.service('apiWorkPackages', ApiWorkPackagesService);
