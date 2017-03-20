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
import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from '../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from "../work-packages/work-package-cache.service";
import IRootScopeService = angular.IRootScopeService;
import {WorkPackageEditModeStateService} from "../wp-edit/wp-edit-mode-state.service";
import {WorkPackageNotificationService} from '../wp-edit/wp-notification.service';
import {WorkPackageTableSelection} from '../wp-fast-table/state/wp-table-selection.service';
import {States} from '../states.service';

export class WorkPackageCreateController {

  public newWorkPackage:WorkPackageResource|any;
  public parentWorkPackage:WorkPackageResource|any;
  public successState:string;

  public get header():string {
    if (!this.newWorkPackage.type) {
      return this.I18n.t('js.work_packages.create.header_no_type');
    }

    if (this.parentWorkPackage) {
      return this.I18n.t(
        'js.work_packages.create.header_with_parent',
        {
          type: this.newWorkPackage.type.name,
          parent_type: this.parentWorkPackage.type.name,
          id: this.parentWorkPackage.id
        }
      );
    }

    if (this.newWorkPackage.type) {
      return this.I18n.t(
        'js.work_packages.create.header',
        { type: this.newWorkPackage.type.name }
      );
    }

    return '';
  }

  constructor(protected $state:ng.ui.IStateService,
              protected $scope:ng.IScope,
              protected $rootScope:IRootScopeService,
              protected $q:ng.IQService,
              protected $location:ng.ILocationService,
              protected I18n:op.I18n,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected states:States,
              protected loadingIndicator:any,
              protected wpCreate:WorkPackageCreateService,
              protected wpEditModeState:WorkPackageEditModeStateService,
              protected wpTableSelection:WorkPackageTableSelection,
              protected wpCacheService:WorkPackageCacheService) {

    this.newWorkPackageFromParams($state.params)
      .then(wp => {
        this.newWorkPackage = wp;
        this.wpEditModeState.start();
        wpCacheService.updateWorkPackage(wp);

        if ($state.params['parent_id']) {
          wpCacheService.loadWorkPackage($state.params['parent_id']).observeOnScope($scope)
            .subscribe(parent => {
              this.parentWorkPackage = parent;
              this.newWorkPackage.parent = parent;
            });
        }
      })
      .catch(error => {
        if (error.errorIdentifier == "urn:openproject-org:api:v3:errors:MissingPermission") {
          let url: string = $location.absUrl();
          $location.path('/login').search({back_url: url});
          let loginUrl: string = $location.absUrl();
          window.location.href = loginUrl;
        };
        this.wpNotificationsService.handleErrorResponse(error);
      });
  }

  public switchToFullscreen() {
    this.$state.go('work-packages.new', this.$state.params);
  }

  protected newWorkPackageFromParams(stateParams:any) {
    const type = parseInt(stateParams.type);

    return this.wpCreate.createNewTypedWorkPackage(stateParams.projectPath, type);
  }

  public cancelAndBackToList() {
    this.wpEditModeState.cancel();
    this.$state.go('work-packages.list', this.$state.params);
  }

  public saveWorkPackage():Promise<any> {
    return this.wpEditModeState.save();
  }

  public refreshAfterSave(wp:WorkPackageResourceInterface, successState:string) {
    this.wpEditModeState.onSaved();
    this.wpTableSelection.focusOn(wp.id);
    this.loadingIndicator.mainPage = this.$state.go(successState, {workPackageId: wp.id})
      .then(() => {
        this.$rootScope.$emit('workPackagesRefreshInBackground');
        this.wpNotificationsService.showSave(wp, true);
      });
  }
}

wpDirectivesModule.controller('WorkPackageCreateController', WorkPackageCreateController);
