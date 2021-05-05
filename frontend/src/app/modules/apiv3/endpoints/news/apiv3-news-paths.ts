//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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


import { APIv3GettableResource, APIv3ResourceCollection } from "core-app/modules/apiv3/paths/apiv3-resource";
import { TimeEntryResource } from "core-app/modules/hal/resources/time-entry-resource";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { Observable } from "rxjs";
import { CollectionResource } from "core-app/modules/hal/resources/collection-resource";
import {
  Apiv3ListParameters,
  Apiv3ListResourceInterface,
  listParamsString
} from "core-app/modules/apiv3/paths/apiv3-list-resource.interface";
import { NewsResource } from "core-app/modules/hal/resources/news-resource";

export class Apiv3NewsPaths
  extends APIv3ResourceCollection<NewsResource, APIv3GettableResource<NewsResource>>
  implements Apiv3ListResourceInterface<NewsResource> {
  constructor(protected apiRoot:APIV3Service,
              protected basePath:string) {
    super(apiRoot, basePath, 'news');
  }

  /**
   * Load a list of time entries with a given list parameter filter
   * @param params
   */
  public list(params?:Apiv3ListParameters):Observable<CollectionResource<NewsResource>> {
    return this
      .halResourceService
      .get<CollectionResource<TimeEntryResource>>(this.path + listParamsString(params));
  }
}
