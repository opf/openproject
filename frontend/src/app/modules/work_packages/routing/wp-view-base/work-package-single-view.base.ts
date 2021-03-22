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

import { ChangeDetectorRef, Injector } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import { WorkPackageViewFocusService } from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { OpTitleService } from 'core-components/html/op-title.service';
import { AuthorisationService } from "core-app/modules/common/model-auth/model-auth.service";
import { States } from "core-components/states.service";
import { KeepTabService } from "core-components/wp-single-view-tabs/keep-tab/keep-tab.service";

import { HalResourceEditingService } from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { catchError, subscribeOn } from "rxjs/operators";

export class WorkPackageSingleViewBase extends UntilDestroyedMixin {

  @InjectField() states:States;
  @InjectField() I18n!:I18nService;
  @InjectField() keepTab:KeepTabService;
  @InjectField() PathHelper:PathHelperService;
  @InjectField() halEditing:HalResourceEditingService;
  @InjectField() wpTableFocus:WorkPackageViewFocusService;
  @InjectField() notificationService:WorkPackageNotificationService;
  @InjectField() authorisationService:AuthorisationService;
  @InjectField() cdRef:ChangeDetectorRef;
  @InjectField() readonly titleService:OpTitleService;
  @InjectField() readonly apiV3Service:APIV3Service;

  // Static texts
  public text:any = {};

  // Work package resource to be loaded from the cache
  public workPackage:WorkPackageResource;
  public projectIdentifier:string;

  public focusAnchorLabel:string;
  public showStaticPagePath:string;

  constructor(public injector:Injector, protected workPackageId:string) {
    super();
    this.initializeTexts();
  }

  /**
   * Observe changes of work package and re-run initialization.
   * Needs to be run explicitly by descendants.
   */
  protected observeWorkPackage() {
    /** Require the work package once to ensure we're displaying errors */
    this
      .apiV3Service
      .work_packages
      .id(this.workPackageId)
      .requireAndStream()
      .pipe(
        this.untilDestroyed()
      )
      .subscribe((wp:WorkPackageResource) => {
        this.workPackage = wp;
        this.init();
        this.cdRef.detectChanges();
      },
      (error) => this.notificationService.handleRawError(error)
      );
  }

  /**
   * Provide static translations
   */
  protected initializeTexts() {
    this.text.tabs = {};
    ['overview', 'activity', 'relations', 'watchers'].forEach(tab => {
      this.text.tabs[tab] = this.I18n.t('js.work_packages.tabs.' + tab);
    });
  }

  /**
   * Initialize controller after workPackage resource has been loaded.
   */
  protected init() {
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

    // Set authorisation data
    this.authorisationService.initModelAuth('work_package', this.workPackage.$links);

    // Push the current title
    this.titleService.setFirstPart(this.workPackage.subjectWithType(20));

    // Preselect this work package for future list operations
    this.showStaticPagePath = this.PathHelper.workPackagePath(this.workPackageId);

    // Listen to tab changes to update the tab label
    this.keepTab.observable
      .pipe(
        this.untilDestroyed()
      )
      .subscribe((tabs:any) => {
        this.updateFocusAnchorLabel(tabs.active);
      });
  }

  /**
   * Recompute the current tab focus label
   */
  public updateFocusAnchorLabel(tabName:string):string {
    const tabLabel = this.I18n.t('js.label_work_package_details_you_are_here', {
      tab: this.I18n.t('js.work_packages.tabs.' + tabName),
      type: this.workPackage.type.name,
      subject: this.workPackage.subject
    });

    return this.focusAnchorLabel = tabLabel;
  }

  public canViewWorkPackageWatchers() {
    return !!(this.workPackage && this.workPackage.watchers);
  }
}
