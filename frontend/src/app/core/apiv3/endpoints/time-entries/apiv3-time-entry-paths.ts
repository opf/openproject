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

import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { ApiV3Resource } from 'core-app/core/apiv3/cache/cachable-apiv3-resource';
import { StateCacheService } from 'core-app/core/apiv3/cache/state-cache.service';
import { ApiV3FormResource } from 'core-app/core/apiv3/forms/apiv3-form-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiV3TimeEntriesPaths } from 'core-app/core/apiv3/endpoints/time-entries/apiv3-time-entries-paths';
import { HalPayloadHelper } from 'core-app/features/hal/schemas/hal-payload.helper';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

export class ApiV3TimeEntryPaths extends ApiV3Resource<TimeEntryResource> {
  // Static paths
  readonly form = this.subResource('form', ApiV3FormResource);

  /**
   * Update the time entry with the given payload.
   *
   * In case of updating from the hal resource, a schema resource is needed
   * to identify the writable attributes.
   * @param payload
   * @param schema
   */
  public patch(payload:Object, schema:SchemaResource|null = null):Observable<TimeEntryResource> {
    return this
      .halResourceService
      .patch<TimeEntryResource>(this.path, this.extractPayload(payload, schema))
      .pipe(
        tap((resource) => this.touch(resource)),
      );
  }

  /**
   * Delete the time entry under the current path
   */
  public delete():Observable<unknown> {
    return this
      .halResourceService
      .delete<TimeEntryResource>(this.path)
      .pipe(
        tap(() => this.cache.clearSome(this.id.toString())),
      );
  }

  protected createCache():StateCacheService<TimeEntryResource> {
    return (this.parent as ApiV3TimeEntriesPaths).cache;
  }

  /**
   * Extract payload from the given request with schema.
   * This will ensure we will only write writable attributes and so on.
   *
   * @param resource
   * @param schema
   */
  protected extractPayload(resource:HalResource|Object|null, schema:SchemaResource|null = null) {
    if (resource instanceof HalResource && schema) {
      return HalPayloadHelper.extractPayloadFromSchema(resource, schema);
    } if (!(resource instanceof HalResource)) {
      return resource;
    }
    return {};
  }
}
