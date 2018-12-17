//-- copyright
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
//++

import {Injector, OnDestroy} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {takeUntil} from 'rxjs/operators';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {ProjectCacheService} from 'core-components/projects/project-cache.service';
import {OpTitleService} from 'core-components/html/op-title.service';
import {AuthorisationService} from "core-app/modules/common/model-auth/model-auth.service";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {States} from "core-components/states.service";
import {KeepTabService} from "core-components/wp-single-view-tabs/keep-tab/keep-tab.service";
import {WorkPackageTableRefreshService} from "core-components/wp-table/wp-table-refresh-request.service";
import {
  IWorkPackageEditingService,
  IWorkPackageEditingServiceToken
} from "core-components/wp-edit-form/work-package-editing.service.interface";

export class WorkPackageViewController implements OnDestroy {

  public wpCacheService:WorkPackageCacheService = this.injector.get(WorkPackageCacheService);
  public states:States = this.injector.get(States);
  public I18n:I18nService = this.injector.get(I18nService);
  public keepTab:KeepTabService = this.injector.get(KeepTabService);
  public PathHelper:PathHelperService = this.injector.get(PathHelperService);
  public wpTableRefresh:WorkPackageTableRefreshService = this.injector.get(WorkPackageTableRefreshService);
  protected wpEditing:IWorkPackageEditingService = this.injector.get(IWorkPackageEditingServiceToken);
  protected wpTableFocus:WorkPackageTableFocusService = this.injector.get(WorkPackageTableFocusService);
  protected projectCacheService:ProjectCacheService = this.injector.get(ProjectCacheService);
  protected authorisationService:AuthorisationService = this.injector.get(AuthorisationService);

  // Static texts
  public text:any = {};

  // Work package resource to be loaded from the cache
  public workPackage:WorkPackageResource;
  public projectIdentifier:string;

  public focusAnchorLabel:string;
  public showStaticPagePath:string;

  readonly titleService:OpTitleService = this.injector.get(OpTitleService);

  constructor(public injector:Injector, protected workPackageId:string) {
    this.initializeTexts();
  }

  ngOnDestroy():void {
    // Created for interface compliance
  }

  /**
   * Observe changes of work package and re-run initialization.
   * Needs to be run explicitly by descendants.
   */
  protected observeWorkPackage() {
    this.wpCacheService.loadWorkPackage(this.workPackageId).values$()
      .pipe(
        takeUntil(componentDestroyed(this))
      )
      .subscribe((wp:WorkPackageResource) => {
        this.workPackage = wp;
        this.init();
      });
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
    this.projectCacheService
      .require(this.workPackage.project.idFromLink)
      .then(() => {
      this.projectIdentifier = this.workPackage.project.identifier;
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
        takeUntil(componentDestroyed(this))
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

  public get isEditable() {
    return this.workPackage.isEditable;
  }
}
