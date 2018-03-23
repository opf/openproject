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

import {HalRequestService} from 'core-app/modules/hal/services/hal-request.service';
import {PayloadDmService} from 'core-app/modules/dm-services/payload-dm.service';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {QueryFormResource} from 'core-app/modules/hal/resources/query-form-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {ApiV3FilterBuilder} from 'core-components/api/api-v3/api-v3-filter-builder';
import {v3PathToken} from 'core-app/angular4-transition-utils';
import {Inject} from '@angular/core';

export interface PaginationObject {
  pageSize:number;
  offset:number;
}

export class QueryDmService {
  constructor(protected halRequest:HalRequestService,
              @Inject(v3PathToken) protected v3Path:any,
              protected UrlParamsHelper:any,
              protected PayloadDm:PayloadDmService) {
  }

  public find(queryData:Object, queryId?:string, projectIdentifier?:string):Promise<QueryResource> {
    let path:string;

    if (queryId) {
      path = this.v3Path.queries({query: queryId});
    } else {
      path = this.v3Path.queries.default({project: projectIdentifier});
    }

    return this.halRequest
      .get<QueryResource>(path, queryData)
      .toPromise();
  }

  public findDefault(queryData:Object, projectIdentifier?:string):Promise<QueryResource> {
    return this.find(queryData, undefined, projectIdentifier);
  }

  public reload(query:QueryResource, pagination:PaginationObject):Promise<QueryResource> {
    let path = this.v3Path.queries({query: query.id});

    return this.halRequest
      .get<QueryResource>(path, pagination)
      .toPromise();
  }

  public loadResults(query:QueryResource, pagination:PaginationObject):Promise<WorkPackageCollectionResource> {
    if (!query.results) {
      throw 'No results embedded when expected';
    }

    var queryData = this.UrlParamsHelper.buildV3GetQueryFromQueryResource(query, pagination);

    var url = URI(query.results.href!).path();

    return this.halRequest
      .get<WorkPackageCollectionResource>(url, queryData, {caching: {enabled: false} })
      .toPromise();
  }

  public loadIdsUpdatedSince(ids:any, timestamp:any):Promise<WorkPackageCollectionResource> {
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

    return this.halRequest
      .get<WorkPackageCollectionResource>(this.v3Path.wps(), {filters: JSON.stringify(filters)})
      .toPromise();
  }

  public async update(query:QueryResource, form:QueryFormResource) {
    return new Promise<QueryResource>((resolve, reject) => {
      this.extractPayload(query, form)
        .then(payload => {
          let path = this.v3Path.queries({ query: query.id });
          this.halRequest.patch<QueryResource>(path, payload)
            .toPromise()
            .then(resolve)
            .catch(reject)
        })
        .catch(reject);
    });
  }

  public create(query:QueryResource, form:QueryFormResource):Promise<QueryResource> {
    return this.extractPayload(query, form).then(payload => {
      let path = this.v3Path.queries();

      return this.halRequest
        .post<QueryResource>(path, payload)
        .toPromise();
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

  public all(projectIdentifier?:string):Promise<CollectionResource> {
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

    return this.halRequest
      .get<CollectionResource>(this.v3Path.queries(), urlQuery)
      .toPromise();
  }

  private extractPayload(query:QueryResource, form:QueryFormResource):Promise<QueryResource> {
    // Extracting requires having the filter schemas loaded as the dependencies
    // need to be present. This should be handled within the cached information however, so it is fast.
    const promises = _.map(query.filters, filter => filter.schema.$load());

    return Promise
      .all(promises)
      .then(() => this.PayloadDm.extract<QueryResource>(query, form.schema));
  }
}
