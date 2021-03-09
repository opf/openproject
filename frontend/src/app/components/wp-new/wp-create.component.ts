//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { ChangeDetectorRef, Directive, Injector, OnInit, ViewChild } from '@angular/core';
import { StateService, Transition } from '@uirouter/core';
import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import { States } from '../states.service';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { RootResource } from 'core-app/modules/hal/resources/root-resource';
import { WorkPackageCreateService } from './wp-create.service';
import { takeWhile } from 'rxjs/operators';
import { OpTitleService } from 'core-components/html/op-title.service';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { WorkPackageViewFiltersService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import { WorkPackageChangeset } from "core-components/wp-edit/work-package-changeset";
import { WorkPackageViewFocusService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service";
import { EditFormComponent } from "core-app/modules/fields/edit/edit-form/edit-form.component";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";
import * as URI from 'urijs';
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { splitViewRoute } from "core-app/modules/work_packages/routing/split-view-routes.helper";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { HalSource, HalSourceLinks } from "core-app/modules/hal/resources/hal-resource";

@Directive()
export class WorkPackageCreateComponent extends UntilDestroyedMixin implements OnInit {
  public successState:string = splitViewRoute(this.$state);
  public cancelState:string = this.$state.current.data.baseRoute;
  public newWorkPackage:WorkPackageResource;
  public parentWorkPackage:WorkPackageResource;
  public change:WorkPackageChangeset;

  /** Are we in the copying substates ? */
  public copying = false;

  public stateParams = this.$transition.params('to');
  public text = {
    button_settings: this.I18n.t('js.button_settings')
  };

  @ViewChild(EditFormComponent, { static: false }) protected editForm:EditFormComponent;

  /** Explicitly remember destroy state in this abstract base */
  protected destroyed = false;

  constructor(public readonly injector:Injector,
              protected readonly $transition:Transition,
              protected readonly $state:StateService,
              protected readonly I18n:I18nService,
              protected readonly titleService:OpTitleService,
              protected readonly notificationService:WorkPackageNotificationService,
              protected readonly states:States,
              protected readonly wpCreate:WorkPackageCreateService,
              protected readonly wpViewFocus:WorkPackageViewFocusService,
              protected readonly wpTableFilters:WorkPackageViewFiltersService,
              protected readonly pathHelper:PathHelperService,
              protected readonly apiV3Service:APIV3Service,
              protected readonly cdRef:ChangeDetectorRef) {
    super();
  }

  public ngOnInit() {
    this.closeEditFormWhenNewWorkPackageSaved();

    this.showForm();
  }

  public ngOnDestroy() {
    super.ngOnDestroy();
  }

  public switchToFullscreen() {
    this.$state.go('work-packages.new', this.$state.params);
  }

  public onSaved(params:{ savedResource:WorkPackageResource, isInitial:boolean }) {
    const { savedResource, isInitial } = params;

    this.editForm?.cancel(false);

    if (this.successState) {
      this.$state.go(this.successState, { workPackageId: savedResource.id })
        .then(() => {
          this.wpViewFocus.updateFocus(savedResource.id!);
          this.notificationService.showSave(savedResource, isInitial);
        });
    }
  }

  protected showForm() {
    this
      .createdWorkPackage()
      .then((changeset:WorkPackageChangeset) => {
        this.change = changeset;
        this.newWorkPackage = changeset.pristineResource;
        this.cdRef.detectChanges();

        this.setTitle();

        if (this.stateParams['parent_id']) {
          changeset.setValue(
            'parent',
            { href: this.apiV3Service.work_packages.id(this.stateParams['parent_id']).path }
          );
        }

        // Load the parent simply to display the type name :-/
        if (this.stateParams['parent_id']) {
          this
            .apiV3Service
            .work_packages
            .id(this.stateParams['parent_id'])
            .get()
            .pipe(
              this.untilDestroyed()
            )
            .subscribe(parent => {
              this.parentWorkPackage = parent;
              this.cdRef.detectChanges();
            });
        }
      })
      .catch((error:any) => {
        if (error.errorIdentifier === 'urn:openproject-org:api:v3:errors:MissingPermission') {
          this.apiV3Service.root.get().subscribe((root:RootResource) => {
            if (!root.user) {
              // Not logged in
              const url = URI(this.pathHelper.loginPath());
              url.search({ back_url: url });
              window.location.href = url.toString();
            }
          });
          this.notificationService.handleRawError(error);
        }
      });
  }

  protected setTitle() {
    this.titleService.setFirstPart(this.I18n.t('js.work_packages.create.title'));
  }

  public cancelAndBackToList() {
    this.wpCreate.cancelCreation();
    this.$state.go(this.cancelState, this.$state.params);
  }

  protected createdWorkPackage() {
    const defaults:HalSource = {
      _links: {}
    };

    const type = this.stateParams.type ? parseInt(this.stateParams.type) : undefined;
    const parent = this.stateParams.parent_id ? parseInt(this.stateParams.parent_id) : undefined;
    const project = this.stateParams.projectPath;

    if (type) {
      defaults._links['type'] = { href: this.apiV3Service.types.id(type).path };
    }
    if (parent) {
      defaults._links['parent'] = { href: this.apiV3Service.work_packages.id(parent).path };
    }

    return this.wpCreate.createOrContinueWorkPackage(project, type, defaults);
  }

  private closeEditFormWhenNewWorkPackageSaved() {
    this.wpCreate
      .onNewWorkPackage()
      .pipe(
        takeWhile(() => !this.componentDestroyed)
      )
      .subscribe((wp:WorkPackageResource) => {
        this.onSaved({ savedResource: wp, isInitial: true });
      });
  }
}
