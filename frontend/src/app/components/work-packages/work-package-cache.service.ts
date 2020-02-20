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

import {MultiInputState, State} from 'reactivestates';
import {States} from '../states.service';
import {StateCacheService} from '../states/state-cache.service';
import {SchemaCacheService} from './../schemas/schema-cache.service';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {Injectable} from '@angular/core';
import {debugLog} from "core-app/helpers/debug_output";
import {WorkPackageDmService} from "core-app/modules/hal/dm-services/work-package-dm.service";

function getWorkPackageId(id:string|null):string {
  return (id || 'new').toString();
}

@Injectable()
export class WorkPackageCacheService extends StateCacheService<WorkPackageResource> {

  /*@ngInject*/
  constructor(private states:States,
              private schemaCacheService:SchemaCacheService,
              private workPackageDmService:WorkPackageDmService) {
    super();
  }

  public updateValue(id:string, val:WorkPackageResource) {
    this.updateWorkPackageList([val], false);
  }

  updateWorkPackage(wp:WorkPackageResource, immediate:boolean = false):Promise<void> {
    const wpId = getWorkPackageId(wp.id!);

    if (immediate || wp.isNew) {
      this.multiState.get(wpId).putValue(wp);
      return Promise.resolve();
    } else {
      return this.schemaCacheService.ensureLoaded(wp).then(() => {
        this.multiState.get(wpId).putValue(wp);
      });
    }
  }

  updateWorkPackageList(list:WorkPackageResource[], skipOnIdentical = true) {
    for (var i of list) {
      const wp = i;
      const workPackageId = getWorkPackageId(wp.id!);
      const state = this.multiState.get(workPackageId);

      // If the work package is new, ignore the schema
      if (wp.isNew) {
        state.putValue(wp);
        continue;
      }

      // Ensure the schema is loaded
      // so that no consumer needs to call schema#$load manually
      this.schemaCacheService.ensureLoaded(wp).then(() => {
        // Check if the work package has changed
        if (skipOnIdentical && state.hasValue() && _.isEqual(state.value!.$source, wp.$source)) {
          debugLog('Skipping identical work package from updating');
          return;
        }

        this.multiState.get(workPackageId).putValue(wp);
      });
    }
  }

  /**
   * Wrapper around `require(id)`.
   *
   * @deprecated
   */
  loadWorkPackage(workPackageId:string, forceUpdate = false):State<WorkPackageResource> {
    const state = this.state(workPackageId);

    // Several services involved in the creation of work packages
    // use this method to resolve the latest created work package,
    // so let them just subscribe.
    if (workPackageId === 'new') {
      return state;
    }

    this.require(workPackageId, forceUpdate);
    return state;
  }

  protected loadAll(ids:string[]) {
    return new Promise<undefined>((resolve, reject) => {
      this.workPackageDmService
        .loadWorkPackagesCollectionsFor(_.uniq(ids))
        .then((pagedResults:WorkPackageCollectionResource[]) => {
          _.each(pagedResults, (results) => {
            if (results.schemas) {
              _.each(results.schemas.elements, (schema:SchemaResource) => {
                this.states.schemas.get(schema.href as string).putValue(schema);
              });
            }

            if (results.elements) {
              this.updateWorkPackageList(results.elements);
            }

            resolve(undefined);
          });
        }, reject);
    });
  }

  protected load(id:string) {
    return new Promise<WorkPackageResource>((resolve, reject) => {

      const errorAndReject = (error:any) => {
        reject(error);
      };

      this.workPackageDmService.loadWorkPackageById(id, true)
        .then((workPackage:WorkPackageResource) => {
          this.schemaCacheService.ensureLoaded(workPackage).then(() => {
            this.multiState.get(id).putValue(workPackage);
            resolve(workPackage);
          }, errorAndReject);
        }, errorAndReject);
    });
  }

  protected get multiState():MultiInputState<WorkPackageResource> {
    return this.states.workPackages;
  }

}
