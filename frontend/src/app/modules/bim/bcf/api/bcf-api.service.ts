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

import {Injectable, Injector} from "@angular/core";
import {BcfResourceCollectionPath} from "core-app/modules/bim/bcf/api/bcf-path-resources";
import {BcfProjectPaths} from "core-app/modules/bim/bcf/api/projects/bcf-project.paths";


@Injectable({ providedIn: 'root' })
export class BcfApiService {

  public readonly bcfApiVersion = '2.1';
  public readonly appBasePath = window.appBasePath || '';
  public readonly bcfApiBase = `${this.appBasePath}/api/bcf/${this.bcfApiVersion}`;

  // /api/bcf/:version/projects
  public readonly projects = new BcfResourceCollectionPath(this.injector, this.bcfApiBase, 'projects', BcfProjectPaths);

  constructor(readonly injector:Injector) {
  }

  /**
   * Parse the given string into a BCF resource path
   *
   * @param href
   */
  parse<T>(href:string):T {
    if (!href.startsWith(this.bcfApiBase)) {
      throw new Error(`Cannot parse ${href} into BCF resource.`);
    }

    const parts = href
      .replace(this.bcfApiBase + '/', '')
      .split('/');

    // Try to find a target collection or resource
    let current:any = this;

    for (let i = 0; i < parts.length; i++) {
      let pathOrId:string = parts[i];
      if (pathOrId in current) {
        // Current has a member named like this URL part
        // descend into it
        current = current[pathOrId];
      } else if (current instanceof BcfResourceCollectionPath) {
        // Otherwise, assume we're looking for an ID
        current = current.id(pathOrId);
      } else {
        // Otherwise, return the current
        break;
      }
    }

    return current === this ? undefined : current;
  }
}
