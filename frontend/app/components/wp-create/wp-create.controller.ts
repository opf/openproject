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
import IRootScopeService = angular.IRootScopeService;
import {WorkPackageEditModeStateService} from "../wp-edit/wp-edit-mode-state.service";
import {WorkPackageNotificationService} from '../wp-edit/wp-notification.service';

export class WorkPackageCreateController {
  public newWorkPackage:WorkPackageResource|any;
  public parentWorkPackage:WorkPackageResource|any;
  public successState:string;

  public get header():string {
    if (this.parentWorkPackage) {
      return this.I18n.t(
        'js.work_packages.create.header_with_parent',
        { type: this.parentWorkPackage.type.name, id: this.parentWorkPackage.id }
      );
    }

    return this.I18n.t(
      'js.work_packages.create.header',
      { type: this.newWorkPackage.type.name }
    );
  }

  constructor(protected $state,
              protected $scope,
              protected $rootScope:IRootScopeService,
              protected $q:ng.IQService,
              protected I18n:op.I18n,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected loadingIndicator,
              protected wpCreate:WorkPackageCreateService,
              protected wpEditModeState:WorkPackageEditModeStateService,
              protected wpCacheService:WorkPackageCacheService) {

    this.newWorkPackageFromParams($state.params)
      .then(wp => {
        this.newWorkPackage = wp;
        this.wpEditModeState.start();
        wpCacheService.updateWorkPackage(wp);

        if ($state.params.parent_id) {
          wpCacheService.loadWorkPackage($state.params.parent_id).observe($scope)
            .subscribe(parent => {
              this.parentWorkPackage = parent;
              this.newWorkPackage.parent = parent;
            });
        }
      })
      .catch(error => this.wpNotificationsService.handleErrorResponse(error));
  }

  protected newWorkPackageFromParams(stateParams) {
    const type = parseInt(stateParams.type);

    return this.wpCreate.createNewTypedWorkPackage(stateParams.projectPath, type);
  }

  public cancelAndBackToList() {
    this.wpEditModeState.cancel();
    this.$state.go('work-packages.list', this.$state.params);
  }

  public saveWorkPackage(successState:string):ng.IPromise<WorkPackageResource> {
    if (this.wpEditModeState.active) {
      return this.wpEditModeState.save().then(wp => {
        this.newWorkPackage = null;
        this.refreshAfterSave(wp, successState);
        return wp;
      });
    }

    return this.$q.reject();
  }

  private refreshAfterSave(wp, successState) {
    this.loadingIndicator.mainPage = this.$state.go(successState, {workPackageId: wp.id})
      .then(() => {
        this.$rootScope.$emit('workPackagesRefreshInBackground');
        this.wpNotificationsService.showSave(wp, true);
      });
  }
}

wpDirectivesModule.controller('WorkPackageCreateController', WorkPackageCreateController);
