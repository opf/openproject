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
import {PayloadDmService} from './payload-dm.service.ts';

export interface PaginationObject {
  pageSize:number,
  offset:number
}

export class QueryDmService {
  constructor(protected halRequest:HalRequestService,
              protected v3Path:any,
              protected UrlParamsHelper:any,
              protected PayloadDm:PayloadDmService) {
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

    var queryData = this.UrlParamsHelper.buildV3GetQueryFromQueryResource(query, pagination);

    var url = query.results.href || '';
    url = url.substring(0, url.indexOf('?'))

    return this.halRequest.get(url, queryData, {caching: {enabled: false} });
  }

  public save(query:QueryResource, form:FormResource) {
    let payload = this.PayloadDm.extract(query, form.schema);

    return query.updateImmediately(payload);
  }

  public create(query:QueryResource, form:FormResource):ng.IPromise<QueryResource> {
    let payload = this.PayloadDm.extract(query, form.schema);

    return form.commit(payload);
  }

  public delete(query:QueryResource) {
    return query.delete();
  }

  public toggleStarred(query:QueryResource) {
    if (query.starred) {
      return query.unstar() as ng.IPromise<QueryResource>;
    } else {
      return query.star() as ng.IPromise<QueryResource>;
    }
  }

  public all(projectIdentifier?:string):ng.IPromise<CollectionResource> {
    let urlQuery = {};

    if (projectIdentifier) {
      urlQuery = {
                   filters: JSON.stringify([{
                     project_identifier: {
                       operator: '=',
                       values: [projectIdentifier],
                     }
                   }]),
                 };
    }

    let caching = {
                    caching: {enabled: false}
                  };

    return this.halRequest.get(this.v3Path.queries(),
                               urlQuery,
                               caching);
  }
}

opApiModule.service('QueryDm', QueryDmService);
