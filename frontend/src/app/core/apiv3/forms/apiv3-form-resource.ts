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

import { ApiV3ResourcePath } from 'core-app/core/apiv3/paths/apiv3-resource';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { Observable } from 'rxjs';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { HalPayloadHelper } from 'core-app/features/hal/schemas/hal-payload.helper';

export class ApiV3FormResource<T extends FormResource = FormResource> extends ApiV3ResourcePath<T> {
  /**
   * POST to the form resource identified by this path
   * @param request The request payload
   */
  public post(request:object = {}, schema:SchemaResource|null = null):Observable<T> {
    return this
      .halResourceService
      .post<T>(
      this.path,
      this.extractPayload(request, schema),
    );
  }

  /**
   * Extract payload for the form from the request and optional schema.
   *
   * @param request
   * @param schema
   */
  public extractPayload(request:T|object, schema:SchemaResource|null = null) {
    return HalPayloadHelper.extractPayload(request, schema);
  }
}
