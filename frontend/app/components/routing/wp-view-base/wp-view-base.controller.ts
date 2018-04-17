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
import {I18nToken} from 'core-app/angular4-transition-utils';
import {PathHelperService} from 'core-components/common/path-helper/path-helper.service';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {takeUntil} from 'rxjs/operators';
import {States} from '../../states.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';
import {KeepTabService} from '../../wp-single-view-tabs/keep-tab/keep-tab.service';
import {WorkPackageTableRefreshService} from '../../wp-table/wp-table-refresh-request.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {ProjectCacheService} from 'core-components/projects/project-cache.service';

export class WorkPackageViewController implements OnDestroy {

  public wpCacheService:WorkPackageCacheService = this.injector.get(WorkPackageCacheService);
  public states:States = this.injector.get(States);
  public I18n:op.I18n = this.injector.get(I18nToken);
  public keepTab:KeepTabService = this.injector.get(KeepTabService);
  public PathHelper:PathHelperService = this.injector.get(PathHelperService);
  public wpTableRefresh:WorkPackageTableRefreshService = this.injector.get(WorkPackageTableRefreshService);
  protected wpEditing:WorkPackageEditingService = this.injector.get(WorkPackageEditingService);
  protected wpTableFocus:WorkPackageTableFocusService = this.injector.get(WorkPackageTableFocusService);
  protected projectCacheService:ProjectCacheService = this.injector.get(ProjectCacheService);

  // Static texts
  public text:any = {};

  // Work package resource to be loaded from the cache
  public workPackage:WorkPackageResource;
  public projectIdentifier:string;

  protected focusAnchorLabel:string;
  public showStaticPagePath:string;

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
