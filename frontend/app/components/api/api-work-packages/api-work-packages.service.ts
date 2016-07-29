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
import {WorkPackageResource,} from '../api-v3/hal-resources/work-package-resource.service';
import IPromise = angular.IPromise;

export class ApiWorkPackagesService {
  constructor(protected DEFAULT_PAGINATION_OPTIONS,
              protected $stateParams,
              protected $q:ng.IQService,
              protected halRequest:HalRequestService,
              protected v3Path) {
  }

  public list(offset:number, pageSize:number, query:api.ex.Query) {
    const params = this.queryAsV3Params(offset, pageSize, query);
    return this.halRequest.get(this.v3Path.wp({project: query.projectId}), params, {
      caching: {enabled: false}
    });
  }

  /**
   * Loads a WorkPackage.
   *
   * @param id The ID of the WorkPackage.
   * @param force Bypass any cached value?
   * @returns {IPromise<any>|IPromise<WorkPackageResource>} A promise for the WorkPackage.
   */
  public loadWorkPackageById(id:number, force = false) {
    const url = this.v3Path.wp({wp: id});

    return <IPromise<WorkPackageResource>> this.halRequest.get(url, null, {
      caching: {
        enabled: !force
      }
    });
  }

  /**
   * Returns a promise to post `/api/v3/work_packages/form`.
   *
   * @returns An empty work package form resource.
   */
  public emptyCreateForm(projectIdentifier?:string):ng.IPromise<HalResource> {
    return this.halRequest.post(this.v3Path.wp.form({project: projectIdentifier}));
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
  public createWorkPackage(payload):ng.IPromise<WorkPackageResource> {
    return this.halRequest.post(this.v3Path.wps(), payload);
  }

  protected queryAsV3Params(offset:number, pageSize:number, query:api.ex.Query) {
    const v3Filters = _.map(query.filters, (filter:any) => {
      const newFilter = {};
      newFilter[filter.name] = {operator: filter.operator, values: filter.values};
      return newFilter;
    });

    const params:op.QueryParams = {
      offset: offset,
      pageSize: pageSize,
      filters: [v3Filters]
    };

    if (query.groupBy) {
      params.groupBy = query.groupBy;
    }

    if (query.displaySums) {
      params.showSums = query.displaySums;
    }

    if (query.sortCriteria && query.sortCriteria.length > 0) {
      params.sortBy = [query.sortCriteria];
    }

    return params;
  }
}

opApiModule.service('apiWorkPackages', ApiWorkPackagesService);
