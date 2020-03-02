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

import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {SchemaCacheService} from "core-components/schemas/schema-cache.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class TimeEntryResource extends HalResource {
  // TODO: extract the whole overridden Schema stuff into halresource or use the schemaCacheService
  // to place it there
  @InjectField() schemaCacheService:SchemaCacheService;

  public overriddenSchema:SchemaResource|undefined = undefined;

  /**
   * Get the current schema, assuming it is either:
   * 1. Overridden by the current loaded form
   * 2. Available as a schema state
   *
   * If it is neither, an exception is raised.
   */
  public get schema():SchemaResource {
    if (this.hasOverriddenSchema) {
      return this.overriddenSchema!;
    }

    const state = this.schemaCacheService.state(this as any);

    if (!state.hasValue()) {
      throw `Accessing schema of ${this.id} without it being loaded.`;
    }

    return state.value!;
  }

  public get hasOverriddenSchema():boolean {
    return this.overriddenSchema != null;
  }

  public get state() {
    return this.states.timeEntries.get(this.id!) as any;
  }

  /**
   * Exclude the schema _link from the linkable Resources.
   */
  public $linkableKeys():string[] {
    return _.without(super.$linkableKeys(), 'schema');
  }
}
