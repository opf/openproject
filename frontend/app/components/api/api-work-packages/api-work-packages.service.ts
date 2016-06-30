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

import {HalResource} from '../hal/hal-resource/hal-resource.service';
import {opApiModule} from '../../../angular-modules';

interface IServiceWithList extends restangular.IService {
  getList(subElement?: any, queryParams?: any, headers?: any): restangular.ICollectionPromise<any>;
  getList<T>(subElement?: any, queryParams?: any, headers?: any): restangular.ICollectionPromise<T>;
  post(subElement: any, elementToPost: any, queryParams?: any, headers?: any): ng.IPromise<any>;
  post<T>(subElement: any, elementToPost: T, queryParams?: any, headers?: any): ng.IPromise<T>;
  post(elementToPost: any, queryParams?: any, headers?: any): ng.IPromise<any>;
  post<T>(elementToPost: T, queryParams?: any, headers?: any): ng.IPromise<T>;
}

export class ApiWorkPackagesService {
  protected wpBaseApi;

  constructor(protected DEFAULT_PAGINATION_OPTIONS,
              protected $stateParams,
              protected $q:ng.IQService,
              protected apiV3:restangular.IService) {

    this.wpBaseApi = apiV3.service('work_packages');
  }

  public list(offset:number, pageSize:number, query:api.ex.Query) {
    var workPackages = this.wpApiPath(query.projectId);

    return workPackages.getList(
      this.queryAsV3Params(offset, pageSize, query), {caching: {enabled: false}}
    );
  }

  /**
   * Loads a WorkPackage.
   *
   * @param id The ID of the WorkPackage.
   * @returns {IPromise<any>|IPromise<WorkPackageResource>} A promise for the WorkPackage.
   */
  public loadWorkPackageById(id: number) {
    return this.apiV3.one('work_packages', id).get({});
  }

  /**
   * Returns a promise to post `/api/v3/work_packages/form`.
   *
   * @returns An empty work package form resource.
   */
  public emptyCreateForm(projectIdentifier?:string):ng.IPromise<HalResource> {
    return this.wpApiPath(projectIdentifier).one('form').customPOST();
  }

  /**
   * Returns a promise to GET `/api/v3/work_packages/available_projects`.
   */
  public availableProjects(projectIdentifier?:string):ng.IPromise<HalResource> {
    return this.wpApiPath(projectIdentifier).one('available_projects').get();
  }

  public wpApiPath(projectIdentifier?:any):IServiceWithList {
    var parent;

    if (!!projectIdentifier) {
      parent = this.apiV3.one('projects', projectIdentifier);
    }

    return <IServiceWithList> this.apiV3.service('work_packages', parent);
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
