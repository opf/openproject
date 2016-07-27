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

import {wpControllersModule} from '../../../angular-modules';
import {WorkPackageViewController} from '../wp-view-base/wp-view-base.controller';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {UserResource} from '../../api/api-v3/hal-resources/user-resource.service';
import {HalResource} from '../../api/api-v3/hal-resources/hal-resource.service';

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

  constructor(public $injector,
              public $scope,
              public $state,
              public $window,
              public HookService,
              public AuthorisationService,
              public WorkPackageAuthorization,
              public PERMITTED_MORE_MENU_ACTIONS) {
    super($injector, $scope, $state.params['workPackageId']);
    this.observeWorkPackage();
  }

  protected init() {
    super.init();

    // initialization
    this.initializeAllowedActions();
    this.setWorkPackageScopeProperties(this.workPackage);
  }

  public deleteSelectedWorkPackage() {
    var promise = this.WorkPackageService.performBulkDelete([this.workPackage.id], true);

    promise.success(function () {
      this.$state.go('work-packages.list', { projectPath: this.projectIdentifier });
    });
  }

  public triggerMoreMenuAction(action, link) {
    switch (action) {
      case 'delete':
        this.deleteSelectedWorkPackage();
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

  private getPermittedActions(authorization, permittedMoreMenuActions) {
    var permittedActions = authorization.permittedActionsWithLinks(permittedMoreMenuActions);
    var augmentedActions = { };

    angular.forEach(permittedActions, function(permission) {
      var css = ['icon-' + permission.key];

      this[permission.key] = { link: permission.link, css: css };
    }, augmentedActions);

    return augmentedActions;
  }

  private getPermittedPluginActions(authorization) {
    var pluginActions = [];
    angular.forEach(this.HookService.call('workPackageDetailsMoreMenu'), function(action) {
      pluginActions = pluginActions.concat(action);
    });

    var permittedPluginActions = authorization.permittedActionsWithLinks(pluginActions);
    var augmentedPluginActions = { };

    angular.forEach(permittedPluginActions, function(action) {
      var css = [].concat(action.css);

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
    this.authorPath = this.author.showUserPath;
    this.authorActive = this.author.isActive;

    // Attachments
    this.attachments = wp.attachments.elements;
  }
}

wpControllersModule.controller('WorkPackageShowController', WorkPackageShowController);
