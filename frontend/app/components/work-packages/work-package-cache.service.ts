import {WorkPackagesListService} from './../wp-list/wp-list.service';
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


import {opWorkPackagesModule} from "../../angular-modules";
import {WorkPackageResource} from "../api/api-v3/hal-resources/work-package-resource.service";
import {SchemaResource} from './../api/api-v3/hal-resources/schema-resource.service';
import {ApiWorkPackagesService} from "../api/api-work-packages/api-work-packages.service";
import {State} from "../../helpers/reactive-fassade";
import IScope = angular.IScope;
import {States} from "../states.service";
import {Observable, Subject} from "rxjs";


function getWorkPackageId(id: number|string): string {
  return (id || "__new_work_package__").toString();
}

export class WorkPackageCacheService {

  private newWorkPackageCreatedSubject = new Subject<WorkPackageResource>();

  /*@ngInject*/
  constructor(private states: States,
              private $q: ng.IQService,
              private apiWorkPackages: ApiWorkPackagesService) {
  }

  newWorkPackageCreated(wp: WorkPackageResource) {
    this.newWorkPackageCreatedSubject.next(wp);
  }

  updateWorkPackage(wp: WorkPackageResource) {
    this.updateWorkPackageList([wp]);
  }

  updateWorkPackageList(list: WorkPackageResource[]) {
    for (var wp of list) {
      const workPackageId = getWorkPackageId(wp.id);
      const wpState = this.states.workPackages.get(workPackageId);
      const wpForPublish = wpState.hasValue() && wpState.getCurrentValue().dirty
        ? wpState.getCurrentValue() // dirty, use current wp
        : wp; // not dirty or unknown, use new wp

      // Ensure the schema is loaded
      // so that no consumer needs to call schema#$load manually
      if (wpForPublish.schema.$loaded) {
        wpState.put(wpForPublish);
      } else {
        wpState.putFromPromise(wpForPublish.schema.$load().then(() => {
          return wpForPublish;
        }));
      }
    }
  }

  loadWorkPackage(workPackageId: string, forceUpdate = false): State<WorkPackageResource> {
    const state = this.states.workPackages.get(getWorkPackageId(workPackageId));
    if (forceUpdate) {
      state.clear();
    }

    // Several services involved in the creation of work packages
    // use this method to resolve the latest created work package,
    // so let them just subscribe.
    if (workPackageId === 'new') {
      return state;
    }

    state.putFromPromiseIfPristine(() => {
      const deferred = this.$q.defer();

      this.apiWorkPackages.loadWorkPackageById(workPackageId, forceUpdate)
        .then((workPackage:WorkPackageResource) => {
          workPackage.schema.$load().then(() => {
            deferred.resolve(workPackage);
          });
        });

      return deferred.promise;
    });

    return state;
  }

  onNewWorkPackage(): Observable<WorkPackageResource> {
    return this.newWorkPackageCreatedSubject.asObservable();
  }

}

opWorkPackagesModule.service('wpCacheService', WorkPackageCacheService);
