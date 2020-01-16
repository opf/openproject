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
import {Injectable} from '@angular/core';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {StatusResource} from "core-app/modules/hal/resources/status-resource";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";

@Injectable()
export class StatusDmService {
  constructor(protected halResourceService:HalResourceService,
              protected pathHelper:PathHelperService) {
  }

  public one(id:string|number):Promise<StatusResource> {
    return this.halResourceService
      .get<StatusResource>(this.pathHelper.api.v3.statuses.id(id).toString())
      .toPromise();
  }

  public list():Promise<CollectionResource<StatusResource>> {
    return this.halResourceService
      .get<CollectionResource<StatusResource>>(this.pathHelper.api.v3.statuses.toString())
      .toPromise();
  }


}
