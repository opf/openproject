// -- copyright
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
// ++
import {InputState, MultiInputState, State} from 'reactivestates';
import {States} from '../states.service';
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {Injectable} from '@angular/core';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {StateCacheService} from "core-components/states/state-cache.service";

@Injectable()
export class SchemaCacheService extends StateCacheService<SchemaResource>{

  constructor(readonly states:States,
              readonly halResourceService:HalResourceService) {
    super();
  }

  public state(id:string|HalResource):State<SchemaResource> {
    let href:string;

    if (id instanceof HalResource) {
      href = this.getSchemaHref(id);
    } else {
      href = id;
    }

    return super.state(href);
  }

  public getSchemaHref(resource:HalResource):string {
    let href = resource.$links.schema?.href;

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
  ensureLoaded(resource:HalResource):Promise<SchemaResource> {
    return this.require(this.getSchemaHref(resource));
  }

  /**
   * Load the associated schema for the given work package, if needed.
   */
  load(href:string, forceUpdate = false):Promise<SchemaResource> {
    return this
      .halResourceService
      .get<SchemaResource>(href)
      .toPromise();
  }

  protected loadAll(hrefs:string[]):Promise<unknown|undefined> {
    return Promise.all(hrefs.map(href => this.load(href)));
  }

  protected get multiState():MultiInputState<SchemaResource> {
    return this.states.schemas;
  }
}
