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

import {wpDirectivesModule} from '../../angular-modules';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {States} from '../states.service';
import {RootDmService} from '../api/api-v3/hal-resource-dms/root-dm.service';
import {RootResource} from '../api/api-v3/hal-resources/root-resource.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../wp-edit/wp-notification.service';
import {WorkPackageCreateService} from './wp-create.service';
import {scopedObservable} from '../../helpers/angular-rx-utils';
import {WorkPackageEditingService} from '../wp-edit-form/work-package-editing-service';
import {WorkPackageChangeset} from '../wp-edit-form/work-package-changeset';

export class WorkPackageCreateController {
  public newWorkPackage:WorkPackageResourceInterface;
  public parentWorkPackage:WorkPackageResourceInterface;
  public changeset:WorkPackageChangeset;

  public get header():string {
    const type = this.changeset.value('type');

    if (!type) {
      return this.I18n.t('js.work_packages.create.header_no_type');
    }

    if (this.parentWorkPackage) {
      return this.I18n.t(
        'js.work_packages.create.header_with_parent',
        {
          type: type.name,
          parent_type: this.parentWorkPackage.type.name,
          id: this.parentWorkPackage.id
        }
      );
    }

    if (type) {
      return this.I18n.t(
        'js.work_packages.create.header',
        {type: type.name}
      );
    }

    return '';
  }

  constructor(protected $state:ng.ui.IStateService,
              protected $scope:ng.IScope,
              protected $q:ng.IQService,
              protected I18n:op.I18n,
              protected successState:string,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected states:States,
              protected wpCreate:WorkPackageCreateService,
              protected wpEditing:WorkPackageEditingService,
              protected wpCacheService:WorkPackageCacheService,
              protected v3Path:any,
              protected $location:ng.ILocationService,
              protected RootDm:RootDmService) {

    this.newWorkPackageFromParams($state.params)
      .then((changeset:WorkPackageChangeset) => {
        this.changeset = changeset;
        this.newWorkPackage = changeset.workPackage;
        this.wpEditing.updateValue('new', changeset);
        wpCacheService.updateWorkPackage(changeset.workPackage);

        if ($state.params['parent_id']) {
          this.changeset.setValue(
            'parent',
            {href: v3Path.wp({wp: $state.params['parent_id']})}
          );
        }

        // Load the parent simply to display the type name :-/
        if ($state.params['parent_id']) {
          scopedObservable(this.$scope,
            wpCacheService.loadWorkPackage($state.params['parent_id']).values$())
            .subscribe(parent => {
              this.parentWorkPackage = parent;
            });
        }
      })
      .catch(error => {
        if (error.errorIdentifier === 'urn:openproject-org:api:v3:errors:MissingPermission') {
          this.RootDm.load().then((root:RootResource) => {
            if (!root.user) {
              // Not logged in
              let url:string = $location.absUrl();
              $location.path('/login').search({back_url: url});
              let loginUrl:string = $location.absUrl();
              window.location.href = loginUrl;
            }
          });
          this.wpNotificationsService.handleErrorResponse(error);
        }
      });
  }

  public switchToFullscreen() {
    this.$state.go('work-packages.new', this.$state.params);
  }

  protected newWorkPackageFromParams(stateParams:any) {
    const type = parseInt(stateParams.type);

    // If there is an open edit for this type, continue it
    const changeset = this.wpEditing.state('new').value;
    if (changeset !== undefined) {
      const changeType = changeset.workPackage.type;

      const hasChanges = !changeset.empty;
      const typeEmpty = (!changeType && !type);
      const typeMatches = (changeType && changeType.idFromLink === type.toString());

      if (hasChanges && (typeEmpty || typeMatches)) {
        return this.$q.when(changeset);
      }
    }

    return this.wpCreate.createNewTypedWorkPackage(stateParams.projectPath, type);
  }

  public cancelAndBackToList() {
    this.wpEditing.stopEditing(this.newWorkPackage.id);
    this.$state.go('work-packages.list', this.$state.params);
  }
}

wpDirectivesModule.controller('WorkPackageCreateController', WorkPackageCreateController);
