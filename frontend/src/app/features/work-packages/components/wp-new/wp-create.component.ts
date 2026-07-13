//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectorRef, Directive, Injector, Input, OnInit, ViewChild, OnDestroy, inject } from '@angular/core';
import {
  StateService,
  Transition,
} from '@uirouter/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { RootResource } from 'core-app/features/hal/resources/root-resource';
import { takeWhile } from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { EditFormComponent } from 'core-app/shared/components/fields/edit/edit-form/edit-form.component';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import URI from 'urijs';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { OpTitleService } from 'core-app/core/html/op-title.service';
import { WorkPackageCreateService } from './wp-create.service';
import { HalError } from 'core-app/features/hal/services/hal-error';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { HalSource } from 'core-app/features/hal/interfaces';

@Directive()
export class WorkPackageCreateComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  readonly injector = inject(Injector);
  protected readonly $state = inject(StateService);
  protected readonly I18n = inject(I18nService);
  protected readonly titleService = inject(OpTitleService);
  protected readonly notificationService = inject(WorkPackageNotificationService);
  protected readonly states = inject(States);
  protected readonly wpCreate = inject(WorkPackageCreateService);
  protected readonly wpViewFocus = inject(WorkPackageViewFocusService);
  protected readonly wpTableFilters = inject(WorkPackageViewFiltersService);
  protected readonly pathHelper = inject(PathHelperService);
  protected readonly apiV3Service = inject(ApiV3Service);
  protected readonly currentProjectService = inject(CurrentProjectService);
  protected readonly cdRef = inject(ChangeDetectorRef);

  public successState:string = splitViewRoute(this.$state);

  public cancelState:string = this.$state?.current?.data?.baseRoute;

  public newWorkPackage:WorkPackageResource;

  public parentWorkPackage:WorkPackageResource;

  public change:WorkPackageChangeset;

  /** Are we in the copying substates ? */
  public copying = false;

  @Input() public stateParams:any;

  public text = {
    button_settings: this.I18n.t('js.button_settings'),
  };

  @Input() public routedFromAngular = true;

  @ViewChild(EditFormComponent, { static: false }) protected editForm:EditFormComponent;

  /** Explicitly remember destroy state in this abstract base */
  protected destroyed = false;

  public ngOnInit() {
    // In case the create form is still routed via Angular, the stateParams are empty. We then read the params from the Transition
    if (this.routedFromAngular) {
      const transition = this.injector.get<Transition>(Transition);
      this.stateParams = transition.params('to');
    }

    this.closeEditFormWhenNewWorkPackageSaved();

    this.showForm();

    window.OpenProject.pageState = 'edited';
  }

  public ngOnDestroy() {
    super.ngOnDestroy();
  }

  public onSaved(params:{ savedResource:WorkPackageResource, isInitial:boolean }) {
    const { savedResource, isInitial } = params;

    this.editForm?.cancel(false);

    if(this.routedFromAngular && this.successState) {
      this.$state.go(this.successState, { workPackageId: savedResource.displayId })
        .then(() => {
          this.wpViewFocus.updateFocus(savedResource.id!);
          this.notificationService.showSave(savedResource, isInitial);
        });
    } else {
      window.OpenProject.pageState = 'submitted';
      Turbo.visit(this.pathHelper.projectWorkPackagePath(savedResource.project.identifier, savedResource.displayId) + window.location.search);
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

        if (this.stateParams.parent_id) {
          changeset.setValue(
            'parent',
            { href: this.apiV3Service.work_packages.id(this.stateParams.parent_id).path },
          );
        }

        // Load the parent simply to display the type name :-/
        if (this.stateParams.parent_id) {
          this
            .apiV3Service
            .work_packages
            .id(this.stateParams.parent_id)
            .get()
            .pipe(
              this.untilDestroyed(),
            )
            .subscribe((parent) => {
              this.parentWorkPackage = parent;
              this.cdRef.detectChanges();
            });
        }
      })
      .catch((error:unknown) => {
        if (error instanceof HalError && error.errorIdentifier === 'urn:openproject-org:api:v3:errors:MissingPermission') {
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

  public cancelAndBack() {
    this.wpCreate.cancelCreation();

    if (this.routedFromAngular) {
      this.$state.go(this.cancelState, this.$state.params);
    } else {
      const link = this.stateParams.projectPath ? this.pathHelper.workPackagesPath(this.stateParams.projectPath) : this.pathHelper.workPackagesPath(null);
      window.location.href = (link + window.location.search);
    }
  }

  protected createdWorkPackage() {
    const defaults:HalSource = (this.stateParams.defaults as HalSource) || {};
    defaults._links = defaults._links || {};

    const type = this.stateParams.type ? parseInt(this.stateParams.type) : undefined;
    const parent = this.stateParams.parent_id ? parseInt(this.stateParams.parent_id) : undefined;
    const project = this.stateParams.projectPath;

    if (type) {
      defaults._links.type = { href: this.apiV3Service.types.id(type).path };
    }
    if (parent) {
      defaults._links.parent = { href: this.apiV3Service.work_packages.id(parent).path };
    }

    return this.wpCreate.createOrContinueWorkPackage(project, type, defaults);
  }

  private closeEditFormWhenNewWorkPackageSaved() {
    this.wpCreate
      .onNewWorkPackage()
      .pipe(
        takeWhile(() => !this.componentDestroyed),
      )
      .subscribe((wp:WorkPackageResource) => {
        this.onSaved({ savedResource: wp, isInitial: true });
      });
  }
}
