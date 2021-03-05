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

import { TimeEntryResource } from "core-app/modules/hal/resources/time-entry-resource";
import { CachableAPIV3Resource } from "core-app/modules/apiv3/cache/cachable-apiv3-resource";
import { StateCacheService } from "core-app/modules/apiv3/cache/state-cache.service";
import { MultiInputState } from "reactivestates";
import { APIv3FormResource } from "core-app/modules/apiv3/forms/apiv3-form-resource";
import { SchemaResource } from "core-app/modules/hal/resources/schema-resource";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { Observable } from "rxjs";
import { tap } from "rxjs/operators";
import { Apiv3TimeEntriesPaths } from "core-app/modules/apiv3/endpoints/time-entries/apiv3-time-entries-paths";
import { HalPayloadHelper } from "core-app/modules/hal/schemas/hal-payload.helper";

export class Apiv3TimeEntryPaths extends CachableAPIV3Resource<TimeEntryResource> {
  // Static paths
  readonly form = this.subResource('form', APIv3FormResource);

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
        tap(resource => this.touch(resource))
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
        tap(() => this.cache.clearSome(this.id.toString()))
      );
  }

  protected createCache():StateCacheService<TimeEntryResource> {
    return (this.parent as Apiv3TimeEntriesPaths).cache;
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
    } else if (!(resource instanceof HalResource)) {
      return resource;
    } else {
      return {};
    }
  }
}
