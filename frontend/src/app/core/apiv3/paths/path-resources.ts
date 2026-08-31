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

import { Constructor } from 'core-app/core/util-types';

/**
 * Simple resource collection to construct paths for RESTful resources.
 * Base class for APIV3 and BCF API helpers
 */
export class SimpleResourceCollection<T = SimpleResource> {
  // Base path
  public readonly path:string;

  constructor(protected basePath:string, readonly segment:string, protected resource?:Constructor<T>) {
    this.path = `${this.basePath}/${segment}`;
  }

  public id(id:string|number):T {
    return new (this.resource || SimpleResource)(this.path, id) as T;
  }

  /**
   * Returns either the collection itself, or the resource
   * located by the ID when present.
   *
   * TypeScript will reduce available endpoints to anything available
   * in this collection AND the resource.
   *
   * @param id
   */
  public withOptionalId(id?:string|number):this|T {
    if (id == null) {
      return this;
    }
    return this.id(id);
  }

  public toString():string {
    return this.path;
  }

  public toPath():string {
    return this.path;
  }
}

/**
 * Singular RESTful resource object identified by a base path and ID
 */
export class SimpleResource {
  public readonly path:string;

  constructor(readonly basePath:string, readonly segment:string|number) {
    const separator = segment.toString().startsWith('?') ? '' : '/';
    this.path = `${this.basePath}${separator}${segment}`;
  }

  public toString() {
    return this.path;
  }

  public toPath():string {
    return this.path;
  }
}
