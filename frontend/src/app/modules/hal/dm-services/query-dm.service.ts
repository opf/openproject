//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {PayloadDmService} from 'core-app/modules/hal/dm-services/payload-dm.service';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {QueryFormResource} from 'core-app/modules/hal/resources/query-form-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {Injectable} from '@angular/core';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {Observable} from "rxjs";
import {QueryFiltersService} from "core-components/wp-query/query-filters.service";
import {DmListParameter} from "core-app/modules/hal/dm-services/dm.service.interface";
import {AbstractDmService} from "core-app/modules/hal/dm-services/abstract-dm.service";
import {HttpClient} from "@angular/common/http";
import * as URI from 'urijs';

export interface PaginationObject {
  pageSize:number;
  offset:number;
}

@Injectable()
export class QueryDmService extends AbstractDmService<QueryResource> {
  constructor(protected halResourceService:HalResourceService,
              protected http:HttpClient,
              protected pathHelper:PathHelperService,
              protected UrlParamsHelper:UrlParamsHelperService,
              protected QueryFilters:QueryFiltersService,
              protected PayloadDm:PayloadDmService) {
    super(halResourceService,
      pathHelper);
  }

  /**
   * Stream the response for the given query request
   * @param queryData
   * @param queryId
   * @param projectIdentifier
   */
  public stream(queryData:Object, queryId?:string, projectIdentifier?:string|null):Observable<QueryResource> {
    let path:string;

    if (queryId) {
      path = this.pathHelper.api.v3.queries.id(queryId).toString();
    } else {
      path = this.pathHelper.api.v3.withOptionalProject(projectIdentifier).queries.default.toString();
    }

    return this.halResourceService
      .get<QueryResource>(path, queryData);
  }

  public find(queryData:Object, queryId?:string, projectIdentifier?:string|null):Promise<QueryResource> {
    return this.stream(queryData, queryId, projectIdentifier).toPromise();
  }

  public findDefault(queryData:Object, projectIdentifier?:string|null):Promise<QueryResource> {
    return this.find(queryData, undefined, projectIdentifier);
  }

  public reload(query:QueryResource, pagination:PaginationObject):Promise<QueryResource> {
    let path = this.pathHelper.api.v3.queries.id(query.id!).toString();

    return this.halResourceService
      .get<QueryResource>(path, pagination)
      .toPromise();
  }

  public loadResults(query:QueryResource, pagination:PaginationObject):Promise<QueryResource> {
    if (!query.results) {
      throw 'No results embedded when expected';
    }

    let queryData = this.UrlParamsHelper.buildV3GetQueryFromQueryResource(query, pagination);
    let url = URI(query.href!).path();

    return this.halResourceService
      .get<QueryResource>(url, queryData)
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
      .get<WorkPackageCollectionResource>(this.pathHelper.api.v3.work_packages.toString(), { filters: JSON.stringify(filters) })
      .toPromise();
  }

  public update(query:QueryResource, form:QueryFormResource):Observable<QueryResource> {
    const payload = this.extractPayload(query, form);
    return this.patch(query.id!, payload);
  }

  public patch(id:string, payload:{ [key:string]:unknown }):Observable<QueryResource> {
    let path:string = this.pathHelper.api.v3.queries.id(id).toString();
    return this.halResourceService
      .patch<QueryResource>(path, payload);
  }

  public create(query:QueryResource, form:QueryFormResource):Promise<QueryResource> {
    const payload:any = this.extractPayload(query, form);
    let path:string = this.pathHelper.api.v3.queries.toString();

    return this.halResourceService
      .post<QueryResource>(path, payload)
      .toPromise();
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

  public listNonHidden(projectIdentifier:string|null|undefined):Promise<CollectionResource<QueryResource>> {
    let listParams:DmListParameter = {
      filters: [['hidden', '=', ['f']]]
    };

    if (projectIdentifier) {
      // all queries with the provided projectIdentifier
      listParams.filters!.push(['project_identifier', '=', [projectIdentifier]]);
    } else {
      // all queries having no project (i.e. being global)
      listParams.filters!.push(['project', '!*', []]);
    }
    return this.list(listParams);
  }

  private extractPayload(query:QueryResource, form:QueryFormResource):QueryResource {
    // Extracting requires having the filter schemas loaded as the dependencies
    this.QueryFilters.mapSchemasIntoFilters(query, form);
    return this.PayloadDm.extract<QueryResource>(query, form.schema);
  }

  protected listUrl():string {
    return this.pathHelper.api.v3.queries.toString();
  }

  protected oneUrl(id:number|string):string {
    return this.pathHelper.api.v3.queries.id(id).toString();
  }
}
