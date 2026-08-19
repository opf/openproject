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

import { ChangeDetectorRef, Directive, Injector, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  WorkPackageViewFocusService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { OpTitleService } from 'core-app/core/html/op-title.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { States } from 'core-app/core/states/states.service';
import {
  KeepTabService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HookService } from 'core-app/features/plugins/hook-service';
import { WpSingleViewService } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.service';
import { Observable } from 'rxjs';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { AttachmentsResourceService } from 'core-app/core/state/attachments/attachments.service';
import { StoragesResourceService } from 'core-app/core/state/storages/storages.service';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import { ProjectsResourceService } from 'core-app/core/state/projects/projects.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { HttpErrorResponse } from '@angular/common/http';
import { StateService } from '@uirouter/angular';

@Directive()
export abstract class WorkPackageSingleViewBase extends UntilDestroyedMixin {
  injector = inject(Injector);

  @Input() routedFromAngular = true;

  @Input() workPackageId:string;

  @Input() activeTab = 'activity';

  readonly states = inject(States);

  readonly $state = inject(StateService);

  readonly i18n = inject(I18nService);

  readonly keepTab = inject(KeepTabService);

  readonly PathHelper = inject(PathHelperService);

  readonly halEditing = inject(HalResourceEditingService);

  readonly wpTableFocus = inject(WorkPackageViewFocusService);

  readonly notificationService = inject(WorkPackageNotificationService);

  readonly authorisationService = inject(AuthorisationService);

  private readonly attachmentsResourceService = inject(AttachmentsResourceService);

  private readonly fileLinkResourceService = inject(FileLinksResourceService);

  private readonly projectsResourceService = inject(ProjectsResourceService);

  private readonly storages = inject(StoragesResourceService);

  private readonly toastService = inject(ToastService);

  readonly cdRef = inject(ChangeDetectorRef);

  readonly titleService = inject(OpTitleService);

  readonly apiV3Service = inject(ApiV3Service);

  readonly hooks = inject(HookService);

  readonly actions$ = inject(ActionsService);

  readonly storeService = inject(WpSingleViewService);

  // Work package resource to be loaded from the cache
  public workPackage:WorkPackageResource;

  public projectIdentifier:string;

  public focusAnchorLabel:string;

  public showStaticPagePath:string;

  public displayNotificationsButton$:Observable<boolean>;

  constructor() {
    super();

    if (this.routedFromAngular && this.workPackageId === undefined) {
      this.workPackageId = this.$state.params.workPackageId as string;
    }
  }

  /**
   * Observe changes of work package and re-run initialization.
   * Needs to be run explicitly by descendants.
   *
   * Note: this.workPackageId may be a semantic identifier (e.g. "PROJ-7")
   * from the route param. In that case the initial load and stream are
   * keyed under the semantic id, but cache writes elsewhere (e.g.
   * cache.updateWorkPackage on save) key by the numeric PK on wp.id.
   * If they differ, we open a parallel subscription on the numeric slot
   * after the first emission so subsequent updates reach us — otherwise
   * this.workPackage would freeze at the initial load. In classic mode
   * (route param == numeric PK) no parallel subscription is opened, so
   * the emission count is unchanged from the original behavior.
   */
  protected observeWorkPackage():void {
    this
      .apiV3Service
      .work_packages
      .id(this.workPackageId)
      .requireAndStream()
      .pipe(this.untilDestroyed())
      .subscribe((wp:WorkPackageResource) => {
        if (wp.id && this.workPackageId !== wp.id) {
          this.workPackageId = wp.id;
          this.subscribeToNumericCacheSlot(wp.id);
        }

        this.applyWorkPackage(wp);
      }, (error) => {
        this.handleLoadingError(error);
      });
  }

  private subscribeToNumericCacheSlot(numericId:string):void {
    this
      .apiV3Service
      .work_packages
      .cache
      .state(numericId)
      .values$()
      .pipe(this.untilDestroyed())
      .subscribe((nextWp:WorkPackageResource) => this.applyWorkPackage(nextWp));
  }

  private applyWorkPackage(wp:WorkPackageResource):void {
    if (!this.workPackage) {
      this.workPackage = wp;
      this.init();
    } else {
      this.workPackage = wp;
    }

    if (this.routedFromAngular) {
      // Push the current title
      this.titleService.setFirstPart(this.workPackage.subjectWithType(-1));
    }

    this.cdRef.detectChanges();
  }

  /**
   * Initialize controller after workPackage resource has been loaded.
   */
  protected init():void {
    // Set elements
    this
      .apiV3Service
      .projects
      .id(this.workPackage.project)
      .requireAndStream()
      .subscribe(() => {
        this.projectIdentifier = this.workPackage.project.identifier;
        this.cdRef.detectChanges();
      });

    // lazy load the work package's project, needed when initializing
    // the work package resource from split view.
    this.projectsResourceService
      .requireEntity((this.workPackage.$links.project as HalResource).href!)
      .subscribe(
        () => {},
        (error:HttpErrorResponse) => {
          this.toastService.addError(error);
        },
      );

    this.displayNotificationsButton$ = this.storeService.hasNotifications$;
    this.storeService.setFilters(this.workPackage.id!);

    // Set authorisation data
    this.authorisationService.initModelAuth('work_package', this.workPackage.$links);

    // Preselect this work package for future list operations
    this.showStaticPagePath = this.PathHelper.workPackagePath(this.workPackageId);

    // Fetch attachments of current work package
    if (this.workPackage.$links.attachments) {
      this.attachmentsResourceService.fetchCollection(this.workPackage.$links.attachments.href!).subscribe();
    }

    // Listen to tab changes to update the tab label
    this.keepTab.observable
      .pipe(this.untilDestroyed())
      .subscribe((tabs:{ active:string }) => {
        this.updateFocusAnchorLabel(tabs.active);
      });
  }

  protected handleLoadingError(error:unknown):void {
    this.notificationService.handleRawError(error);
  }

  /**
   * Recompute the current tab focus label
   */
  public updateFocusAnchorLabel(tabName:string):string {
    this.focusAnchorLabel = this.i18n.t('js.label_work_package_details_you_are_here', {
      tab: this.i18n.t(`js.work_packages.tabs.${tabName}`),
      type: this.workPackage.type.name,
      subject: this.workPackage.subject,
    });
    return this.focusAnchorLabel;
  }
}
