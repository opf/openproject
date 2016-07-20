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

import {opApiModule} from '../../../../angular-modules';
import {HalResource} from '../hal-resources/hal-resource.service';

export class HalRequestService {
  constructor(protected $q:ng.IQService,
              protected $http:ng.IHttpService,
              protected HalResource) {
  }

  /**
   * Perform a HTTP request and return a HalResource promise.
   *
   * @param method
   * @param href
   * @param data
   * @returns {IPromise<HalResource>}
   */
  public request(method:string, href:string, data?:any):ng.IPromise<HalResource> {
    if (!href) {
      return this.$q.when(null);
    }

    return this.$http({
      method: method,
      url: href,
      data: data
    })
      .then(response => this.HalResource.init(response.data))
      .catch(response => this.HalResource.init(response.data));
  }

  /**
   * Perform a GET request and return a resource promise.
   *
   * @param href
   * @returns {ng.IPromise<HalResource>}
   */
  public get(href:string):ng.IPromise<HalResource> {
    return this.request('get', href);
  }

  /**
   * Perform a PUT request and return a resource promise.
   * @param href
   * @param data
   * @returns {ng.IPromise<HalResource>}
   */
  public put(href:string, data?:any):ng.IPromise<HalResource> {
    return this.request('put', href, data);
  }

  /**
   * Perform a POST request and return a resource promise.
   *
   * @param href
   * @param data
   * @returns {ng.IPromise<HalResource>}
   */
  public post(href:string, data?:any):ng.IPromise<HalResource> {
    return this.request('post', href, data);
  }

  /**
   * Perform a PATCH request and return a resource promise.
   *
   * @param href
   * @param data
   * @returns {ng.IPromise<HalResource>}
   */
  public patch(href:string, data?:any):ng.IPromise<HalResource> {
    return this.request('patch', href, data);
  }

  /**
   * Perform a DELETE request and return a resource promise
   *
   * @param href
   * @param data
   * @returns {ng.IPromise<HalResource>}
   */
  public delete(href:string, data?:any):ng.IPromise<HalResource> {
    return this.request('delete', href, data);
  }
}

opApiModule.service('halRequest', HalRequestService);
