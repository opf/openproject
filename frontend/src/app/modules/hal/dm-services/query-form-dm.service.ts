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
import {Inject, Injectable} from '@angular/core';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {QueryFormResource} from 'core-app/modules/hal/resources/query-form-resource';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';

@Injectable()
export class QueryFormDmService {
  constructor(readonly halResourceService:HalResourceService,
              protected pathHelper:PathHelperService) {
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
      payload['name'] = '!!!__O__o__O__!!!';
    }

    if (projectIdentifier) {
      payload['_links'] = {
        'project': {
          'href': this.pathHelper.api.v3.projects.id(projectIdentifier).toString()
        }
      };
    }

    let href:string = this.pathHelper.api.v3.queries.optionalId(queryId).form.toString();
    href = URI(href).search(params).toString();

    return this.halResourceService
      .post<QueryFormResource>(href, payload)
      .toPromise();
  }
}
