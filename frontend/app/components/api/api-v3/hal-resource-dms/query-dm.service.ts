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

import {QueryResource} from '../hal-resources/query-resource.service';
import {CollectionResource} from '../hal-resources/collection-resource.service';
import {WorkPackageCollectionResource} from '../hal-resources/wp-collection-resource.service';
import {FormResource} from '../hal-resources/form-resource.service';
import {opApiModule} from '../../../../angular-modules';
import {HalRequestService} from '../hal-request/hal-request.service';
import {PayloadDmService} from './payload-dm.service';
import {ApiV3FilterBuilder} from '../api-v3-filter-builder';
import {QueryFormResource} from "core-components/api/api-v3/hal-resources/query-form-resource.service";

export interface PaginationObject {
  pageSize:number;
  offset:number;
}

export class QueryDmService {
  constructor(protected halRequest:HalRequestService,
              protected v3Path:any,
              protected UrlParamsHelper:any,
              protected PayloadDm:PayloadDmService,
              protected $q:ng.IQService) {
  }

  public find(queryData:Object, queryId?:string, projectIdentifier?:string):ng.IPromise<QueryResource> {
    let path:string;

    if (queryId) {
      path = this.v3Path.queries({query: queryId});
    } else {
      path = this.v3Path.queries.default({project: projectIdentifier});
    }

    return this.halRequest.get(path,
                               queryData,
                               {caching: {enabled: false} });
  }

  public findDefault(queryData:Object, projectIdentifier?:string):ng.IPromise<QueryResource> {
    return this.find(queryData, undefined, projectIdentifier);
  }

  public reload(query:QueryResource, pagination:PaginationObject):ng.IPromise<QueryResource> {
    let path = this.v3Path.queries({query: query.id});

    return this.halRequest.get(path,
                               pagination,
                               {caching: {enabled: false} });
  }

  public loadResults(query:QueryResource, pagination:PaginationObject):ng.IPromise<WorkPackageCollectionResource> {
    if (!query.results) {
      throw 'No results embedded when expected';
    }

    var queryData = this.UrlParamsHelper.buildV3GetQueryFromQueryResource(query, pagination);

    var url = URI(query.results.href!).path();

    return this.halRequest.get(url, queryData, {caching: {enabled: false} });
  }

  public loadIdsUpdatedSince(ids:any, timestamp:any):ng.IPromise<WorkPackageCollectionResource> {
    const filters = [
      {
        id: {
          operator: '=',
          values: ids.filter((n:String|null) => n) // no null values
        },
      },
      {
        updatedAt: {
          operator: '<>d',
          values: [timestamp, '']
        }
      }
    ];

    return this.halRequest.get(this.v3Path.wps(),
                               {filters: JSON.stringify(filters)},
                               {caching: {enabled: false} });
  }

  public update(query:QueryResource, form:QueryFormResource) {
    return new Promise<QueryResource>((resolve, reject) => {
      this.extractPayload(query, form)
        .then(payload => {
          let path = this.v3Path.queries({ query: query.id });
          this.halRequest.patch<QueryResource>(path, payload)
            .then(resolve)
            .catch(reject)
        })
        .catch(reject);
    });
  }

  public create(query:QueryResource, form:QueryFormResource):ng.IPromise<QueryResource> {
    return this.extractPayload(query, form).then(payload => {
      let path = this.v3Path.queries();

      return this.halRequest.post(path, payload);
    });
  }

  public delete(query:QueryResource) {
    return query.delete();
  }

  public toggleStarred(query:QueryResource) {
    if (query.starred) {
      return query.unstar();
    } else {
      return query.star();
    }
  }

  public all(projectIdentifier?:string):ng.IPromise<CollectionResource> {
    let filters = new ApiV3FilterBuilder();

    if (projectIdentifier) {
      // all queries with the provided projectIdentifier
      filters.add('project_identifier', '=',  [projectIdentifier]);
    } else {
      // all queries having no project (i.e. being global)
      filters.add('project', '!*', []);
    }

    let urlQuery = { filters: filters.toJson() };
    let caching = { caching: {enabled: false} };

    return this.halRequest.get(this.v3Path.queries(),
                               urlQuery,
                               caching);
  }

  private extractPayload(query:QueryResource, form:QueryFormResource) {
    // Extracting requires having the filter schemas loaded as the dependencies
    // need to be present. This should be handled within the cached information however, so it is fast.
    return this.$q.all(_.map(query.filters, filter => filter.schema.$load())).then(() => {
      return this.PayloadDm.extract<QueryResource>(query, form.schema);
    });
  }
}

opApiModule.service('QueryDm', QueryDmService);
