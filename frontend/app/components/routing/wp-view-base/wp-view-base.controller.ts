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

import {wpControllersModule} from '../../../angular-modules';
import {scopedObservable} from '../../../helpers/angular-rx-utils';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {States} from '../../states.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {KeepTabService} from '../../wp-panels/keep-tab/keep-tab.service';
import {WorkPackageTableRefreshService} from '../../wp-table/wp-table-refresh-request.service';
import {$injectFields} from '../../angular/angular-injector-bridge.functions';
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';

export class WorkPackageViewController {

  protected $q:ng.IQService;
  protected $state:ng.ui.IStateService;
  protected states:States;
  protected $rootScope:ng.IRootScopeService;
  protected keepTab:KeepTabService;
  protected wpCacheService:WorkPackageCacheService;
  protected WorkPackageService:any;
  protected PathHelper:op.PathHelper;
  protected I18n:op.I18n;
  protected wpTableRefresh:WorkPackageTableRefreshService;
  protected wpEditing:WorkPackageEditingService;

  // Helper promise to detect when the controller has been initialized
  // (when a WP has loaded).
  public initialized:ng.IDeferred<any>;

  // Static texts
  public text:any = {};

  // Work package resource to be loaded from the cache
  public workPackage:WorkPackageResourceInterface;
  public projectIdentifier:string;

  protected focusAnchorLabel:string;
  public showStaticPagePath:string;

  constructor(public $scope:ng.IScope,
              protected workPackageId:string) {
    $injectFields(this, '$q', '$state', 'keepTab', 'wpCacheService', 'WorkPackageService',
      'states', 'wpEditing', 'PathHelper', 'I18n', 'wpTableRefresh');

    this.initialized = this.$q.defer();
    this.initializeTexts();
  }

  /**
   * Observe changes of work package and re-run initialization.
   * Needs to be run explicitly by descendants.
   */
  protected observeWorkPackage() {
    scopedObservable(this.$scope, this.wpCacheService.loadWorkPackage(this.workPackageId).values$())
      .subscribe((wp:WorkPackageResourceInterface) => {
        this.workPackage = wp;
        this.init();
        this.initialized.resolve();
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
    this.workPackage.project.$load().then(() => {
      this.projectIdentifier = this.workPackage.project.identifier;
    });

    // Preselect this work package for future list operations
    this.showStaticPagePath = this.PathHelper.workPackagePath(this.workPackage);
    this.states.focusedWorkPackage.putValue(this.workPackage.id);

    // Listen to tab changes to update the tab label
    scopedObservable(this.$scope, this.keepTab.observable).subscribe((tabs:any) => {
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

wpControllersModule.controller('WorkPackageViewController', WorkPackageViewController);
