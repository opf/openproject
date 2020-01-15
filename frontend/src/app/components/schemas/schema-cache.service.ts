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
import {InputState, State} from 'reactivestates';
import {States} from '../states.service';
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {Injectable} from '@angular/core';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';

@Injectable()
export class SchemaCacheService {

  constructor(readonly states:States,
              readonly halResourceService:HalResourceService) {
  }

  /**
   * Ensure the given schema identified by its href is currently loaded.
   * @param href The schema's href.
   * @return A promise with the loaded schema.
   */
  ensureLoaded(resource:HalResource):Promise<unknown> {
    const state = this.state(resource);

    if (state.hasValue()) {
      return Promise.resolve(state.value);
    } else {
      return this.load(resource).valuesPromise() as Promise<unknown>;
    }
  }

  /**
   * Get the associated schema state of the work package
   *  without initializing a new resource.
   */
  state(resource:HalResource):InputState<SchemaResource> {
    const schema = resource.$links.schema;

    if (!schema) {
      throw `Resource ${resource} has no schema!`;
    }

    return this.states.schemas.get(schema.href!);
  }

  /**
   * Load the associated schema for the given work package, if needed.
   */
  load(resource:HalResource, forceUpdate = false):State<SchemaResource> {
    const state = this.state(resource);

    if (forceUpdate) {
      state.clear();
    }

    state.putFromPromiseIfPristine(() => {
      const schemaResource = this.halResourceService.createLinkedResource(resource, 'schema', resource.$links.schema.$link);
      return schemaResource.$load() as any;
    });

    return state;
  }
}
