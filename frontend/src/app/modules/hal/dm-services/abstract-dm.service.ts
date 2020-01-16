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

import {DmListParameter, DmServiceInterface} from "core-app/modules/hal/dm-services/dm.service.interface";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {Injectable} from '@angular/core';

// This only needs to be Injectable for the tests to work
@Injectable()
export abstract class AbstractDmService<T extends HalResource> implements DmServiceInterface {
  constructor(protected halResourceService:HalResourceService,
              protected pathHelper:PathHelperService) {
  }

  public list(params:DmListParameter|null):Promise<CollectionResource<T>> {
    return this.listRequest(this.listUrl(), params) as Promise<CollectionResource<T>>;
  }


  public one(id:number):Promise<T> {
    return this.halResourceService.get<T>(this.oneUrl(id).toString()).toPromise();
  }

  protected listRequest(url:string, params:DmListParameter|null) {
    return this.halResourceService.get(url + this.listParamsString(params)).toPromise();
  }

  protected listParamsString(params:DmListParameter|null):string {
    let queryProps = [];

    if (params && params.sortBy) {
      queryProps.push(`sortBy=${JSON.stringify(params.sortBy)}`);
    }

    // 0 should not be treated as false
    if (params && params.pageSize !== undefined) {
      queryProps.push(`pageSize=${params.pageSize}`);
    }

    if (params && params.filters) {
      let filters = new ApiV3FilterBuilder();

      params.filters.forEach((filterParam) => {
        filters.add(...filterParam);
      });

      queryProps.push(filters.toParams());
    }

    let queryPropsString = '';

    if (queryProps.length) {
      queryPropsString = `?${queryProps.join('&')}`;
    }

    return queryPropsString;
  }


  protected abstract listUrl():string;
  protected abstract oneUrl(id:number|string):string;
}
