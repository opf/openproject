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

import {HalResource} from '../api-v3/hal-resources/hal-resource.service';
import {opApiModule} from '../../../angular-modules';
import {HalRequestService} from '../api-v3/hal-request/hal-request.service';
import {WorkPackageResource, } from '../api-v3/hal-resources/work-package-resource.service';
import {
  WorkPackageCollectionResource,
  WorkPackageCollectionResourceInterface,
} from '../api-v3/hal-resources/wp-collection-resource.service';
import {States} from '../../states.service';
import IPromise = angular.IPromise;
import {SchemaResource} from '../api-v3/hal-resources/schema-resource.service';
import {ApiV3FilterBuilder, buildApiV3Filter} from '../api-v3/api-v3-filter-builder';

export class ApiWorkPackagesService {
  constructor(protected $q:ng.IQService,
              protected halRequest:HalRequestService,
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
  public loadWorkPackageById(id:string, force = false) {
    const url = this.v3Path.wp({wp: id});

    return this.halRequest.get(url, null, {
      caching: {
        enabled: !force
      }
    });
  }

  /**
   * Loads the work packages collection for the given work package IDs.
   * Returns a WP Collection with schemas and results embedded.
   *
   * @param ids
   * @return {WorkPackageCollectionResourceInterface[]}
   */
  public loadWorkPackagesCollectionsFor(ids:string[]) {
    return this.halRequest.getAllPaginated(
      this.v3Path.wps(),
      ids.length,
      {
        filters: buildApiV3Filter('id', '=', ids).toJson(),
      },
      {
        caching: { enabled: false }
      });
  }

  /**
   * Returns a promise to post `/api/v3/work_packages/form`.
   *
   * @returns An empty work package form resource.
   */
  public emptyCreateForm(request:any, projectIdentifier?:string):ng.IPromise<HalResource> {
    return this.halRequest.post(this.v3Path.wp.form({ project: projectIdentifier }), request);
  }

  /**
   * Returns a promise to post `/api/v3/work_packages/form` where the
   * type has already been set to the one provided.
   *
   * @param typeId: The id of the type to initialize the form with
   * @param projectIdentifier: The project to which the work package is initialized
   * @returns An empty work package form resource.
   */
  public typedCreateForm(typeId:number, projectIdentifier?:string):ng.IPromise<HalResource> {

    const typeUrl = this.v3Path.types({type: typeId});
    const request = { _links: { type: { href: typeUrl } } };

    return this.halRequest.post(this.v3Path.wp.form({ project: projectIdentifier }), request);
  }

  /**
   * Returns a promise to GET `/api/v3/work_packages/available_projects`.
   */
  public availableProjects(projectIdentifier?:string):ng.IPromise<HalResource> {
    return this.halRequest.get(this.v3Path.wp.availableProjects({project: projectIdentifier}));
  }

  /**
   * Create a work package from a form payload
   *
   * @param payload
   * @return {ng.IPromise<WorkPackageResource>}
   */
  public createWorkPackage(payload:any):ng.IPromise<WorkPackageResource> {
    return this.halRequest.post(this.v3Path.wps(), payload);
  }
}

opApiModule.service('apiWorkPackages', ApiWorkPackagesService);
