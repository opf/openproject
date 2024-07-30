//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { Observable } from 'rxjs';
import { IView, IViewCreatePayload } from 'core-app/core/state/views/view.model';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { HttpClient } from '@angular/common/http';
import { map } from 'rxjs/operators';
import {
  ApiV3GettableResource,
  ApiV3ResourceCollection,
} from 'core-app/core/apiv3/paths/apiv3-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

export class ApiV3ViewsPaths extends ApiV3ResourceCollection<IView, ApiV3GettableResource<IView>> {
  @InjectField() http:HttpClient;

  constructor(
    protected apiRoot:ApiV3Service,
    protected basePath:string,
  ) {
    super(apiRoot, basePath, 'views');
  }

  /**
   * Create a new view
   *
   * @param resource
   * @param type The query's view type
   */
  post(resource:IViewCreatePayload, type:string):Observable<IView> {
    return this
      .http
      .post(
        `${this.path}/${type}`,
        resource,
        {
          withCredentials: true,
          responseType: 'json',
        },
      ).pipe(
        map((view:IView) => view),
      );
  }
}
