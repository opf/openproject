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

import {wpControllersModule} from "../../../angular-modules";
import {HalResource} from "../../api/api-v3/hal-resources/hal-resource.service";
import {UserResource} from "../../api/api-v3/hal-resources/user-resource.service";
import {WorkPackageResourceInterface} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {WorkPackageViewController} from "../wp-view-base/wp-view-base.controller";

export class WorkPackageShowController extends WorkPackageViewController {

  // Permitted actions for WP toolbar
  public permittedActions:any;
  public actionsAvailable:boolean;

  // Watcher properties
  public isWatched:boolean;
  public displayWatchButton:boolean;
  public watchers:any;

  // Properties
  public type:HalResource;
  public author:UserResource;
  public authorPath:string;
  public authorActive:boolean;
  public attachments:any;

  constructor(public $injector:ng.auto.IInjectorService,
              public $scope:any,
              public $state:ng.ui.IStateService,
              public $window:ng.IWindowService,
              public HookService:any,
              public AuthorisationService:any,
              public WorkPackageAuthorization:any,
              public PERMITTED_MORE_MENU_ACTIONS:any) {
    super($injector, $scope, $state.params['workPackageId']);
    this.observeWorkPackage();
  }

  protected init() {
    super.init();

    // initialization
    this.initializeAllowedActions();
    this.setWorkPackageScopeProperties(this.workPackage);
  }

  public goToList() {
    this.$state.go('work-packages.list', this.$state.params);
  }

  public deleteSelectedWorkPackage() {
    var promise = this.WorkPackageService.performBulkDelete([this.workPackage.id], true);

    promise.then(() => {
      this.$state.go('work-packages.list', { projectPath: this.projectIdentifier });
    });
  }

  public triggerMoreMenuAction(action:string, link:any) {
    switch (action) {
      case 'delete':
        this.deleteSelectedWorkPackage();
        break;
      case 'configure_form':
        this.$window.location.href = `/types/${this.workPackage.type.id}/edit/form_configuration`;
        break;
      default:
        this.$window.location.href = link;
        break;
    }
  };

  /**
   * Load allowed links on this work package.
   * For copying, requires the project to be loaded.
   */
  private initializeAllowedActions() {
    this.workPackage.project.$load().then(() => {
      this.AuthorisationService.initModelAuth('work_package', this.workPackage);

      var authorization = new this.WorkPackageAuthorization(this.workPackage);
      this.$scope.permittedActions = angular.extend(this.getPermittedActions(authorization, this.PERMITTED_MORE_MENU_ACTIONS),
        this.getPermittedPluginActions(authorization));
      this.$scope.actionsAvailable = Object.keys(this.$scope.permittedActions).length > 0;
      this.$scope.triggerMoreMenuAction = this.triggerMoreMenuAction.bind(this);
    });
  }

  private getPermittedActions(authorization:any, permittedMoreMenuActions:any) {
    var permittedActions = authorization.permittedActionsWithLinks(permittedMoreMenuActions);
    var augmentedActions = { };

    angular.forEach(permittedActions, function(this:any, permission) {
      var css = ['icon-' + permission.key];

      this[permission.key] = { link: permission.link, css: css };
    }, augmentedActions);

    return augmentedActions;
  }

  private getPermittedPluginActions(authorization:any) {
    var pluginActions:any = [];
    angular.forEach(this.HookService.call('workPackageDetailsMoreMenu'), function(action) {
      pluginActions = pluginActions.concat(action);
    });

    var permittedPluginActions = authorization.permittedActionsWithLinks(pluginActions);
    var augmentedPluginActions = { };

    angular.forEach(permittedPluginActions, function(this:any, action) {
      var css:string[] = [].concat(action.css);

      if (css.length === 0) {
        css = ["icon-" + action.key];
      }

      this[action.key] = { link: action.link, css: css };
    }, augmentedPluginActions);

    return augmentedPluginActions;
  }

  private setWorkPackageScopeProperties(wp:WorkPackageResourceInterface) {
    this.isWatched = wp.hasOwnProperty('unwatch');
    this.displayWatchButton = wp.hasOwnProperty('unwatch') || wp.hasOwnProperty('watch');

    // watchers
    if (wp.watchers) {
      this.watchers = (wp.watchers as any).elements;
    }

    // Type
    this.type = wp.type;

    // Author
    this.author = wp.author;
    this.authorPath = this.author.showUserPath as string;
    this.authorActive = this.author.isActive;

    // Attachments
    this.attachments = wp.attachments.elements;
  }
}

wpControllersModule.controller('WorkPackageShowController', WorkPackageShowController);
