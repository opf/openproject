//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';
import {States} from '../states.service';
import {PathHelperFunctions} from "../common/path-heleper/path-helper.functions";

var $state:ng.ui.IStateService;
var $window:ng.IWindowService;
var $location:ng.ILocationService;
var states:States;
var HookService:any;
var WorkPackageService:any;
var AuthorisationService:any;
var WorkPackageAuthorization:any;
var PERMITTED_MORE_MENU_ACTIONS:any;

export class WorkPackageMoreMenuService {
  public permittedActions:any;

  constructor(private workPackage:WorkPackageResource) {}

  public deleteSelectedWorkPackage() {
    var promise = WorkPackageService.performBulkDelete([this.workPackage.id], true);

    promise.then(() => {
      states.focusedWorkPackage.clear();

      $state.go('work-packages.list');
    });
  }

  public triggerMoreMenuAction(action:string, link:string) {
    switch (action) {
      case 'delete':
        this.deleteSelectedWorkPackage();
        break;
      default:
        const normalized = PathHelperFunctions.removeBasePathFromLink(link);
        if (this.isLinkToAnguluar(normalized)) {
          $location.path(normalized);
        } else {
          $window.location.href = link;
        }
        break;
    }
  }

  /**
   * Load allowed links on this work package.
   * For copying, requires the project to be loaded.
   */
  public initialize() {
    return this.workPackage.project.$load().then(() => {
      AuthorisationService.initModelAuth('work_package', this.workPackage.$links);

      var authorization = new WorkPackageAuthorization(this.workPackage);
      this.permittedActions = angular.extend(this.getPermittedActions(authorization, PERMITTED_MORE_MENU_ACTIONS),
        this.getPermittedPluginActions(authorization));
    });
  }

  public get actionsAvailable() {
    return Object.keys(this.permittedActions).length > 0;
  }

  private getPermittedActions(authorization:any, permittedMoreMenuActions:any) {
    var permittedActions = authorization.permittedActionsWithLinks(permittedMoreMenuActions);
    var augmentedActions = { };

    angular.forEach(permittedActions, function(this:any, permission) {
      let css = [ (permission.icon || 'icon-' + permission.key) ];

      this[permission.key] = { link: permission.link, css: css };
    }, augmentedActions);

    return augmentedActions;
  }

  private getPermittedPluginActions(authorization:any) {
    var pluginActions:any = [];
    angular.forEach(HookService.call('workPackageDetailsMoreMenu'), function(action) {
      pluginActions = pluginActions.concat(action);
    });

    var permittedPluginActions = authorization.permittedActionsWithLinks(pluginActions);
    var augmentedPluginActions = { };

    angular.forEach(permittedPluginActions, function(this:any, action) {
      var css:string[] = [].concat(action.css);

      if (css.length === 0) {
        css = ['icon-' + action.key];
      }

      this[action.key] = { link: action.link, css: css };
    }, augmentedPluginActions);

    return augmentedPluginActions;
  }

  private isLinkToAnguluar(link:string) {
    var stateForLink = $state.get().filter(state => (state as any).$$state().url.exec(link));

    return stateForLink.length > 0;
  }
}

function wpMoreMenuService(...args:any[]) {
  [$state,
   states,
   $window,
   $location,
   HookService,
   WorkPackageService,
   AuthorisationService,
   WorkPackageAuthorization,
   PERMITTED_MORE_MENU_ACTIONS] = args;
  return WorkPackageMoreMenuService;
}

wpMoreMenuService.$inject = [
  '$state',
  'states',
  '$window',
  '$location',
  'HookService',
  'WorkPackageService',
  'AuthorisationService',
  'WorkPackageAuthorization',
  'PERMITTED_MORE_MENU_ACTIONS'
];

angular
    .module('openproject.workPackages.services')
    .service('wpMoreMenuService', wpMoreMenuService);
