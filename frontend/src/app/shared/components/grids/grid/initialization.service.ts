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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, inject } from '@angular/core';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { switchMap } from 'rxjs/operators';
import {
  Observable,
  of,
} from 'rxjs';

@Injectable()
export class GridInitializationService {
  readonly apiV3Service = inject(ApiV3Service);
  readonly halResourceService = inject(HalResourceService);


  // If a page with the current page exists (scoped to the current user by the backend)
  // that page will be used to initialized the grid.
  // If it does not exist, fetch the form and then create a new resource.
  // The created resource is then used to initialize the grid.
  public initialize(path:string):Observable<GridResource> {
    return this
      .apiV3Service
      .grids
      .list({ filters: [['scope', '=', [path]]] })
      .pipe(
        switchMap((collection) => {
          if (collection.total === 0) {
            return this.myPageForm(path);
          }
          return of(collection.elements[0]);
        }),
      );
  }

  private myPageForm(path:string):Observable<GridResource> {
    const payload = {
      _links: {
        scope: {
          href: path,
        },
      },
    };

    return this
      .apiV3Service
      .grids
      .form
      .post(payload)
      .pipe(
        switchMap((form) => {
          const source = form.payload.$source;
          const resource:GridResource = this.halResourceService.createHalResource(source);

          if (resource.widgets.length === 0) {
            resource.rowCount = 1;
            resource.columnCount = 1;
          }

          return this
            .apiV3Service
            .grids
            .post(resource, form.schema);
        }),
      );
  }
}
