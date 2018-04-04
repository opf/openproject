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

import {Inject, OnDestroy, OnInit} from '@angular/core';
import {StateService, Transition} from '@uirouter/core';
import {$stateToken, I18nToken, v3PathToken} from 'core-app/angular4-transition-utils';
import {PathHelperService} from 'core-components/common/path-helper/path-helper.service';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {takeUntil} from 'rxjs/operators';
import {RootDmService} from '../api/api-v3/hal-resource-dms/root-dm.service';
import {RootResource} from '../api/api-v3/hal-resources/root-resource.service';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {States} from '../states.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageChangeset} from '../wp-edit-form/work-package-changeset';
import {WorkPackageEditingService} from '../wp-edit-form/work-package-editing-service';
import {WorkPackageFilterValues} from '../wp-edit-form/work-package-filter-values';
import {WorkPackageNotificationService} from '../wp-edit/wp-notification.service';
import {WorkPackageTableFiltersService} from '../wp-fast-table/state/wp-table-filters.service';
import {WorkPackageCreateService} from './wp-create.service';

export class WorkPackageCreateController implements OnInit, OnDestroy {
  public successState:string;
  public newWorkPackage:WorkPackageResourceInterface;
  public parentWorkPackage:WorkPackageResourceInterface;
  public changeset:WorkPackageChangeset;

  public stateParams = this.$transition.params('to');
  public text = {
    button_settings: this.I18n.t('js.button_settings')
  };

  constructor(readonly $transition:Transition,
              @Inject($stateToken) readonly $state:StateService,
              @Inject(I18nToken) readonly I18n:op.I18n,
              @Inject(v3PathToken) protected v3Path:any,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected states:States,
              protected wpCreate:WorkPackageCreateService,
              protected wpEditing:WorkPackageEditingService,
              protected wpTableFilters:WorkPackageTableFiltersService,
              protected wpCacheService:WorkPackageCacheService,
              protected PathHelper:PathHelperService,
              protected RootDm:RootDmService) {

  }

  public ngOnInit() {
    this.newWorkPackageFromParams(this.stateParams)
      .then((changeset:WorkPackageChangeset) => {
        this.changeset = changeset;
        this.newWorkPackage = changeset.workPackage;


        this.wpCacheService.updateWorkPackage(this.newWorkPackage);
        this.wpEditing.updateValue('new', changeset);

        if (this.stateParams['parent_id']) {
          this.changeset.setValue(
            'parent',
            {href: this.v3Path.wp({wp: this.stateParams['parent_id']})}
          );
        }

        // Load the parent simply to display the type name :-/
        if (this.stateParams['parent_id']) {
          this.wpCacheService.loadWorkPackage(this.stateParams['parent_id'])
            .values$()
            .pipe(
              takeUntil(componentDestroyed(this))
            )
            .subscribe(parent => {
              this.parentWorkPackage = parent;
            });
        }
      })
      .catch((error:any) => {
        if (error.errorIdentifier === 'urn:openproject-org:api:v3:errors:MissingPermission') {
          this.RootDm.load().then((root:RootResource) => {
            if (!root.user) {
              // Not logged in
              let url = URI(this.PathHelper.loginPath());
              url.search({back_url: url});
              window.location.href = url.toString();
            }
          });
          this.wpNotificationsService.handleErrorResponse(error);
        }
      });
  }

  public ngOnDestroy() {

  }

  public switchToFullscreen() {
    this.$state.go('work-packages.new', this.$state.params);
  }

  protected async newWorkPackageFromParams(stateParams:any):Promise<WorkPackageChangeset> {
    const type = parseInt(stateParams.type);

    // If there is an open edit for this type, continue it
    const changeset = this.wpEditing.state('new').value;
    if (changeset !== undefined) {
      const changeType = changeset.workPackage.type;

      const hasChanges = !changeset.empty;
      const typeEmpty = (!changeType && !type);
      const typeMatches = (changeType && changeType.idFromLink === type.toString());

      if (hasChanges && (typeEmpty || typeMatches)) {
        return Promise.resolve(changeset);
      }
    }

    return this.wpCreate.createNewTypedWorkPackage(stateParams.projectPath, type).then(changeset => {
      const filter = new WorkPackageFilterValues(changeset, this.wpTableFilters.current, ['type']);
      return filter.applyDefaultsFromFilters().then(() => changeset) as ng.IPromise<WorkPackageChangeset>;
    });
  }

  public cancelAndBackToList() {
    this.wpEditing.stopEditing(this.newWorkPackage.id);
    this.$state.go('work-packages.list', this.$state.params);
  }
}
