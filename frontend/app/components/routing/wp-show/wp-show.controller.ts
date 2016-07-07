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

import {scopedObservable} from "../../../helpers/angular-rx-utils";
import {WorkPackageResource} from "../../api/api-v3/hal-resources/work-package-resource.service";

function WorkPackageShowController($scope,
                                   $rootScope,
                                   $state,
                                   $window,
                                   PERMITTED_MORE_MENU_ACTIONS,
                                   I18n,
                                   PathHelper,
                                   WorkPackageService,
                                   WorkPackageAuthorization,
                                   HookService,
                                   AuthorisationService,
                                   wpCacheService,
                                   wpEditModeState) {

  $scope.wpEditModeState = wpEditModeState;

  scopedObservable($scope, wpCacheService.loadWorkPackage($state.params.workPackageId))
    .subscribe((wp: WorkPackageResource) => {
      $scope.workPackage = wp;
      wp.schema.$load();

      AuthorisationService.initModelAuth('work_package', $scope.workPackage);

      var authorization = new WorkPackageAuthorization($scope.workPackage);
      $scope.permittedActions = angular.extend(getPermittedActions(authorization, PERMITTED_MORE_MENU_ACTIONS),
        getPermittedPluginActions(authorization));
      $scope.actionsAvailable = Object.keys($scope.permittedActions).length > 0;

      // END stuff copied from details toolbar directive...

      $scope.I18n = I18n;
      $scope.$parent.preselectedWorkPackageId = $scope.workPackage.id;
      $scope.maxDescriptionLength = 800;
      $scope.projectIdentifier = $scope.workPackage.project.identifier;

      // initialization
      setWorkPackageScopeProperties($scope.workPackage);

    });


  // stuff copied from details toolbar directive...
  function getPermittedActions(authorization, permittedMoreMenuActions) {
    var permittedActions = authorization.permittedActionsWithLinks(permittedMoreMenuActions);
    var augmentedActions = { };

    angular.forEach(permittedActions, function(permission) {
      var css = ['icon-' + permission.key];

      this[permission.key] = { link: permission.link, css: css };
    }, augmentedActions);

    return augmentedActions;
  }

  function getPermittedPluginActions(authorization) {
    var pluginActions = [];
    angular.forEach(HookService.call('workPackageDetailsMoreMenu'), function(action) {
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
  function deleteSelectedWorkPackage() {
    var promise = WorkPackageService.performBulkDelete([$scope.workPackage.id], true);

    promise.success(function() {
      $state.go('work-packages.list', {projectPath: $scope.projectIdentifier});
    });
  }
  $scope.triggerMoreMenuAction = function(action, link) {
    switch (action) {
      case 'delete':
        deleteSelectedWorkPackage();
        break;
      default:
        $window.location.href = link;
        break;
    }
  };

  function outputMessage(message, isError) {
    $scope.$emit('flashMessage', {
      isError: !!isError,
      text: message
    });
  }

  function outputError(error) {
    outputMessage(error.message || I18n.t('js.work_packages.error.general'), true);
  }

  $scope.outputMessage = outputMessage; // expose to child controllers
  $scope.outputError = outputError; // expose to child controllers


  function setWorkPackageScopeProperties(workPackage){
    $scope.isWatched = workPackage.hasOwnProperty('unwatch');
    $scope.displayWatchButton = workPackage.hasOwnProperty('unwatch') ||
      workPackage.hasOwnProperty('watch');

    // watchers
    if(workPackage.watchers) {
      $scope.watchers = workPackage.watchers.elements;
    }

    $scope.showStaticPagePath = PathHelper.workPackagePath($scope.workPackage.id);

    // Type
    $scope.type = workPackage.type;

    // Author
    $scope.author = workPackage.author;
    $scope.authorPath = $scope.author.showUserPath;
    $scope.authorActive = $scope.author.isActive;

    // Attachments
    $scope.attachments = workPackage.attachments.elements;

    $scope.focusAnchorLabel = getFocusAnchorLabel(
      $state.current.url.replace(/\//, ''),
      $scope.workPackage
    );
  }

  $scope.canViewWorkPackageWatchers = function() {
    return !!($scope.workPackage && $scope.workPackage.watchers !== undefined);
  };

  // toggles

  $scope.toggleStates = {
    hideFullDescription: true,
    hideAllAttributes: true
  };

  function getFocusAnchorLabel(tab, workPackage) {
    var tabLabel = I18n.t('js.work_packages.tabs.' + tab),
      params = {
        tab: tabLabel,
        type: workPackage.type.name,
        subject: workPackage.subject
      };

    return I18n.t('js.label_work_package_details_you_are_here', params);
  }
}

angular
  .module('openproject.workPackages.controllers')
  .controller('WorkPackageShowController', WorkPackageShowController);
