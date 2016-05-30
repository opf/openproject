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

import {wpDirectivesModule} from "../../angular-modules";
import {WorkPackageCreateService} from "./wp-create.service";
import {WorkPackageResource} from "../api/api-v3/hal-resources/work-package-resource.service";
import {WorkPackageCacheService} from "../work-packages/work-package-cache.service";
import {scopedObservable} from "../../helpers/angular-rx-utils";
import IRootScopeService = angular.IRootScopeService;

export class WorkPackageCreateController {
  public newWorkPackage:WorkPackageResource;
  public successState:string;

  public get header():string {
    // if (this.parentWorkPackage) {
    //   return this.I18n.t('js.work_packages.create.header_with_parent',
    //     {type: this.parentWorkPackage.type.name, id: this.parentWorkPackage.id });
    // }
    return this.I18n.t('js.work_packages.create.header');

  }

  constructor(protected $state,
              protected $scope,
              protected $rootScope:IRootScopeService,
              protected I18n:op.I18n,
              protected wpCreate:WorkPackageCreateService,
              protected wpCacheService:WorkPackageCacheService) {
    const body = angular.element('body').addClass('full-create');

    $scope.$on('$stateChangeStart', () => {
      body.removeClass('full-create');
    });

    scopedObservable($scope, wpCreate.createNewWorkPackage($state.params.projectPath))
      .subscribe(wp => {
        this.newWorkPackage = wp;
        wpCacheService.updateWorkPackage(wp);
      });
  }

  public goToWorkPackagesList() {
    this.$state.go('work-packages.list', this.$state.params);
  }

  public saveWorkPackage(successState:string) {
    this.wpCreate.saveWorkPackage().then(wp => {
      this.$state.go(successState, {workPackageId: wp.id});
    });
  }
}

wpDirectivesModule.controller('WorkPackageCreateController', WorkPackageCreateController);
