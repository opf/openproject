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

import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {PayloadDmService} from 'core-app/modules/hal/dm-services/payload-dm.service';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {QueryFormResource} from 'core-app/modules/hal/resources/query-form-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {ApiV3FilterBuilder} from 'core-app/components/api/api-v3/api-v3-filter-builder';
import {Injectable} from '@angular/core';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {Observable} from "rxjs";

export interface PaginationObject {
  pageSize:number;
  offset:number;
}

@Injectable()
export class QueryDmService {
  constructor(protected halResourceService:HalResourceService,
              protected pathHelper:PathHelperService,
              protected UrlParamsHelper:UrlParamsHelperService,
              protected PayloadDm:PayloadDmService) {
  }

  /**
   * Stream the response for the given query request
   * @param queryData
   * @param queryId
   * @param projectIdentifier
   */
  public stream(queryData:Object, queryId?:number, projectIdentifier?:string):Observable<QueryResource> {
    let path:string;

    if (queryId) {
      path = this.pathHelper.api.v3.queries.id(queryId).toString();
    } else {
      path = this.pathHelper.api.v3.withOptionalProject(projectIdentifier).queries.default.toString();
    }

    return this.halResourceService
      .get<QueryResource>(path, queryData);
  }

  public find(queryData:Object, queryId?:number, projectIdentifier?:string):Promise<QueryResource> {
    return this.stream(queryData, queryId, projectIdentifier).toPromise();
  }

  public findDefault(queryData:Object, projectIdentifier?:string):Promise<QueryResource> {
    return this.find(queryData, undefined, projectIdentifier);
  }

  public reload(query:QueryResource, pagination:PaginationObject):Promise<QueryResource> {
    let path = this.pathHelper.api.v3.queries.id(query.id).toString();

    return this.halResourceService
      .get<QueryResource>(path, pagination)
      .toPromise();
  }

  public loadResults(query:QueryResource, pagination:PaginationObject):Promise<WorkPackageCollectionResource> {
    if (!query.results) {
      throw 'No results embedded when expected';
    }

    var queryData = this.UrlParamsHelper.buildV3GetQueryFromQueryResource(query, pagination);

    var url = URI(query.results.href!).path();

    return this.halResourceService
      .get<WorkPackageCollectionResource>(url, queryData)
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

    return this.halResourceService
      .get<WorkPackageCollectionResource>(this.pathHelper.api.v3.work_packages.toString(), {filters: JSON.stringify(filters)})
      .toPromise();
  }

  public update(query:QueryResource, form:QueryFormResource) {
    return new Promise<QueryResource>((resolve, reject) => {
      this.extractPayload(query, form)
        .then(payload => {
          let path:string = this.pathHelper.api.v3.queries.id(query.id).toString();
          this.halResourceService.patch<QueryResource>(path, payload)
            .toPromise()
            .then(resolve)
            .catch(reject);
        })
        .catch(reject);
    });
  }

  public create(query:QueryResource, form:QueryFormResource):Promise<QueryResource> {
    return this.extractPayload(query, form).then(payload => {
      let path:string = this.pathHelper.api.v3.queries.toString();

      return this.halResourceService
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

  public all(projectIdentifier:string|null|undefined):Promise<CollectionResource<QueryResource>> {
    let filters = new ApiV3FilterBuilder();

    if (projectIdentifier) {
      // all queries with the provided projectIdentifier
      filters.add('project_identifier', '=',  [projectIdentifier]);
    } else {
      // all queries having no project (i.e. being global)
      filters.add('project', '!*', []);
    }

    // Exclude hidden queries
    filters.add('hidden', '=', ['f']);

    let urlQuery = { filters: filters.toJson() };

    return this.halResourceService
      .get<CollectionResource<QueryResource>>(this.pathHelper.api.v3.queries.toString(), urlQuery)
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
