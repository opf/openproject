// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++
import {State} from "reactivestates";
import {States} from "../states.service";
import {SchemaResource} from "../api/api-v3/hal-resources/schema-resource.service";
import {WorkPackageResourceInterface} from "core-components/api/api-v3/hal-resources/work-package-resource.service";
import {Injectable} from '@angular/core';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {opWorkPackagesModule} from 'core-app/angular-modules';
import {downgradeInjectable} from '@angular/upgrade/static';

@Injectable()
export class SchemaCacheService {

  /*@ngInject*/
  constructor(private states:States) {
  }

  /**
   * Ensure the given schema identified by its href is currently loaded.
   * @param href The schema's href.
   * @return A promise with the loaded schema.
   */
  ensureLoaded(workPackage:WorkPackageResourceInterface):PromiseLike<any> {
    const state = this.state(workPackage);

    if (state.hasValue()) {
      return Promise.resolve(state.value);
    } else {
      return this.load(workPackage).valuesPromise();
    }
  }

  /**
   * Get the associated schema state of the work package
   *  without initializing a new resource.
   */
  state(workPackage:WorkPackageResourceInterface) {
    const schema = workPackage.$links.schema;
    return this.states.schemas.get(schema.href!);
  }

  /**
   * Load the associated schema for the given work package, if needed.
   */
  load(workPackage:WorkPackageResourceInterface, forceUpdate = false):State<SchemaResource> {
    const state = this.state(workPackage);

    if (forceUpdate) {
      state.clear();
    }

    state.putFromPromiseIfPristine(() => {
      const resource = workPackage.createLinkedResource('schema', workPackage.$links.schema.$link);
      return resource.$load() as any;
    });

    return state;
  }
}

opWorkPackagesModule.service('schemaCacheService', downgradeInjectable(SchemaCacheService));
