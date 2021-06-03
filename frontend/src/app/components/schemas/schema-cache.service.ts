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
import { MultiInputState, State } from 'reactivestates';
import { States } from '../states.service';
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { Injectable } from '@angular/core';
import { SchemaResource } from 'core-app/modules/hal/resources/schema-resource';
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { ISchemaProxy, SchemaProxy } from "core-app/modules/hal/schemas/schema-proxy";
import { WorkPackageSchemaProxy } from "core-app/modules/hal/schemas/work-package-schema-proxy";
import { StateCacheService } from "core-app/modules/apiv3/cache/state-cache.service";
import { Observable } from "rxjs";
import { take } from "rxjs/operators";

@Injectable()
export class SchemaCacheService extends StateCacheService<SchemaResource> {

  constructor(readonly states:States,
              readonly halResourceService:HalResourceService) {
    super(states.schemas);
  }

  public state(id:string|HalResource):State<SchemaResource> {
    return super.state(this.stateKey(id));
  }

  /**
   * Returns the schema of the provided resource.
   * This method assumes the schema is loaded and will fail if it is not.
   * @deprecated Assuming the schema to be loaded is deprecated. Rely on the states instead.
   * @param resource The HalResource for which the schema is to be returned
   * @return The schema for the HalResource
   */
  of(resource:HalResource):ISchemaProxy {
    const schema = this.state(resource).value;

    if (!schema) {
      throw `Schema for resource ${resource} was expected to be loaded but isn't.`;
    }

    if (resource._type === 'WorkPackage') {
      return WorkPackageSchemaProxy.create(schema, resource);
    } else {
      return SchemaProxy.create(schema, resource);
    }
  }

  public getSchemaHref(resource:HalResource):string {
    const href = resource.$links.schema?.href;

    if (!href) {
      throw new Error(`Resource ${resource} has no schema to load.`);
    }

    return href;
  }

  /**
   * Ensure the given schema identified by its href is currently loaded.
   * @param resource The resource with a schema property or a string to the schema href.
   * @return A promise with the loaded schema.
   */
  ensureLoaded(resource:HalResource|string):Promise<SchemaResource> {
    const href = resource instanceof HalResource ? this.getSchemaHref(resource) : resource;

    return this
      .requireAndStream(href)
      .pipe(
        take(1)
      )
      .toPromise();
  }

  /**
   * Require the value to be loaded either when forced or the value is stale
   * according to the cache interval specified for this service.
   *
   * Returns an observable to the values stream of the state.
   *
   * @param id The state to require
   * @param force Load the value anyway.
   */
  public requireAndStream(href:string, force = false):Observable<SchemaResource> {
    // Refresh when stale or being forced
    if (this.stale(href) || force) {
      this.clearAndLoad(
        href,
        this.load(href)
      );
    }

    return this.state(href).values$();
  }

  /**
   * Load the associated schema for the given work package, if needed.
   */
  protected load(href:string):Observable<SchemaResource> {
    return this
      .halResourceService
      .get<SchemaResource>(href)
      .pipe(
        take(1)
      );
  }

  protected loadAll(hrefs:string[]):Promise<unknown|undefined> {
    return Promise.all(hrefs.map(href => this.load(href)));
  }

  /**
   * Places the schema in the schema state of the resource.
   * @param resource The resource for which the schema is to be updated
   * @param schema
   */
  update(resource:HalResource, schema:SchemaResource) {
    this.multiState.get(this.stateKey(resource)).putValue(schema);
  }

  private stateKey(id:string|HalResource):string {
    if (id instanceof HalResource) {
      return this.getSchemaHref(id);
    } else {
      return id;
    }
  }
}

