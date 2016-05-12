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
                                   $q,
                                   PERMITTED_MORE_MENU_ACTIONS,
                                   RELATION_TYPES,
                                   RELATION_IDENTIFIERS,
                                   workPackage,
                                   I18n,
                                   WorkPackagesHelper,
                                   PathHelper,
                                   UsersHelper,
                                   WorkPackageService,
                                   CommonRelationsHandler,
                                   ChildrenRelationsHandler,
                                   ParentRelationsHandler,
                                   WorkPackageAuthorization,
                                   HookService,
                                   AuthorisationService,
                                   wpCacheService,
                                   wpEditModeState) {

  $scope.wpEditModeState = wpEditModeState;

  scopedObservable($scope, wpCacheService.loadWorkPackage(workPackage.props.id))
    .subscribe((wp: WorkPackageResource) => {
      $scope.workPackageResource = wp;
    });

  // Listen to the event globally, as listeners are not necessarily
  // in the child scope
  var refreshRequiredFunction = $rootScope.$on('workPackageRefreshRequired', function() {
    refreshWorkPackage();
  });
  $scope.$on('$destroy', refreshRequiredFunction);

  AuthorisationService.initModelAuth('work_package', workPackage.links);

  // initialization
  setWorkPackageScopeProperties(workPackage);

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
    var promise = WorkPackageService.performBulkDelete([$scope.workPackage.props.id], true);

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
  var authorization = new WorkPackageAuthorization($scope.workPackage);
  $scope.permittedActions = angular.extend(getPermittedActions(authorization, PERMITTED_MORE_MENU_ACTIONS),
    getPermittedPluginActions(authorization));
  $scope.actionsAvailable = Object.keys($scope.permittedActions).length > 0;

  // END stuff copied from details toolbar directive...

  $scope.I18n = I18n;
  $scope.$parent.preselectedWorkPackageId = $scope.workPackage.props.id;
  $scope.maxDescriptionLength = 800;
  $scope.projectIdentifier = $scope.workPackage.embedded.project.props.identifier;


  function refreshWorkPackage() {
    WorkPackageService.getWorkPackage($scope.workPackage.props.id)
      .then(function(workPackage) {
        setWorkPackageScopeProperties(workPackage);
        $scope.$broadcast('workPackageRefreshed');
      });
  }

  function outputMessage(message, isError) {
    $scope.$emit('flashMessage', {
      isError: !!isError,
      text: message
    });
  }

  function outputError(error) {
    outputMessage(error.message || I18n.t('js.work_packages.error'), true);
  }

  $scope.outputMessage = outputMessage; // expose to child controllers
  $scope.outputError = outputError; // expose to child controllers


  function setWorkPackageScopeProperties(workPackage){
    $scope.workPackage = workPackage;
    $scope.isWatched = workPackage.links.hasOwnProperty('unwatch');
    $scope.displayWatchButton = workPackage.links.hasOwnProperty('unwatch') ||
      workPackage.links.hasOwnProperty('watch');

    // watchers
    if(workPackage.links.watchers) {
      $scope.watchers = workPackage.embedded.watchers.embedded.elements;
    }

    $scope.showStaticPagePath = PathHelper.workPackagePath($scope.workPackage.props.id);

    // Type
    $scope.type = workPackage.embedded.type;

    // Author
    $scope.author = workPackage.embedded.author;
    $scope.authorPath = PathHelper.userPath($scope.author.props.id);
    $scope.authorActive = UsersHelper.isActive($scope.author);

    // Attachments
    $scope.attachments = workPackage.embedded.attachments.embedded.elements;

    // relations
    $q.all(WorkPackagesHelper.getParent(workPackage)).then(function(parents) {
      var relationsHandler = new ParentRelationsHandler(workPackage, parents, 'parent');
      $scope.wpParent = relationsHandler;
    });

    $q.all(WorkPackagesHelper.getChildren(workPackage)).then(function(children) {
      var relationsHandler = new ChildrenRelationsHandler(workPackage, children);
      $scope.wpChildren = relationsHandler;
    });

    function relationTypeIterator(key) {
      $q.all(WorkPackagesHelper.getRelationsOfType(
        workPackage,
        RELATION_TYPES[key])
      ).then(function(relations) {
        var relationsHandler = new CommonRelationsHandler(workPackage,
          relations,
          RELATION_IDENTIFIERS[key]);
        $scope[key] = relationsHandler;
      });
    }

    for (var key in RELATION_TYPES) {
      if (RELATION_TYPES.hasOwnProperty(key)) {
        relationTypeIterator(key);
      }
    }
  }

  $scope.toggleWatch = function() {
    // Toggle early to avoid delay.
    $scope.isWatched = !$scope.isWatched;
    WorkPackageService.toggleWatch($scope.workPackage)
      .then(function() { refreshWorkPackage() }, outputError);
  };

  $scope.canViewWorkPackageWatchers = function() {
    return !!($scope.workPackage && $scope.workPackage.embedded.watchers !== undefined);
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
        type: workPackage.props.type,
        subject: workPackage.props.subject
      };

    return I18n.t('js.label_work_package_details_you_are_here', params);
  }

  $scope.focusAnchorLabel = getFocusAnchorLabel(
    $state.current.url.replace(/\//, ''),
    $scope.workPackage
  );
}

angular
  .module('openproject.workPackages.controllers')
  .controller('WorkPackageShowController', WorkPackageShowController);
