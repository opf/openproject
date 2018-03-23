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
import {Inject, Injectable} from '@angular/core';
import {v3PathToken} from 'core-app/angular4-transition-utils';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {QueryFormResource} from 'core-app/modules/hal/resources/query-form-resource';

@Injectable()
export class QueryFormDmService {
  constructor(readonly halRequest:HalRequestService,
              @Inject(v3PathToken) protected v3Path:any) {
  }

  public load(query:QueryResource):Promise<QueryFormResource> {
    // We need a valid payload so that we
    // can check whether form saving is possible.
    // The query needs a name to be valid.
    let payload:any = {
      'name': query.name || '!!!__O__o__O__!!!'
    };

    if (query.project) {
      payload['_links'] = {
        'project': {
          'href': query.project.$href
        }
      };
    }

    return query.$links.update(payload);
  }

  public loadWithParams(params:{}, queryId?:number, projectIdentifier?:string):Promise<QueryFormResource> {
    // We need a valid payload so that we
    // can check whether form saving is possible.
    // The query needs a name to be valid.
    let payload:any = {};

    if (!queryId) {
      payload['name'] = '!!!__O__o__O__!!!'
    }

    if (projectIdentifier) {
      payload['_links'] = {
        'project': {
          'href': this.v3Path.project({project: projectIdentifier})
        }
      };
    }

    let href:string;

    if (queryId) {
      href = this.v3Path.queries.form({ query: queryId });
    } else {
      href = this.v3Path.queries.form();
    }

    href = URI(href).search(params).toString();

    return this.halRequest
      .post<QueryFormResource>(href, payload)
      .toPromise();
  }
}
