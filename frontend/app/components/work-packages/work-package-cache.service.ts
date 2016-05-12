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
import {ApiWorkPackagesService} from "../api/api-work-packages/api-work-packages.service";
import IScope = angular.IScope;


export class WorkPackageCacheService {

  private workPackageCache: {[id: number]: WorkPackageResource} = {};

  workPackagesSubject = new Rx.ReplaySubject<{[id: number]: WorkPackageResource}>(1);

  /*@ngInject*/
  constructor(private $rootScope: IScope, private apiWorkPackages: ApiWorkPackagesService) {
  }

  updateWorkPackage(wp: WorkPackageResource) {
    this.updateWorkPackageList([wp]);

    // romanroe: TODO Remove. Only required for 'old' API consumers.
    this.$rootScope.$broadcast('workPackageRefreshRequired');
  }

  updateWorkPackageList(list: WorkPackageResource[]) {
    for (const wp of list) {
      var cached = this.workPackageCache[wp.id];
      if (cached && cached.dirty) {
        this.workPackageCache[wp.id] = cached;
      } else {
        this.workPackageCache[wp.id] = wp;
      }
    }
    this.workPackagesSubject.onNext(this.workPackageCache);
  }

  loadWorkPackage(workPackageId: number, forceUpdate = false): Rx.Observable<WorkPackageResource> {
    if (forceUpdate || this.workPackageCache[workPackageId] === undefined) {
      this.apiWorkPackages.loadWorkPackageById(workPackageId).then(wp => {
        this.updateWorkPackage(wp);
      });
    }

    return this.workPackagesSubject
        .map(cache => cache[workPackageId])
        .filter(wp => wp !== undefined);
  }

}

opWorkPackagesModule.service('wpCacheService', WorkPackageCacheService);
