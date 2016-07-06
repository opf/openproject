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
import {WorkPackageResource} from "../../api/hal/hal-resource/work-package-resource.service";
import {WorkPackageEditModeStateService} from "../../wp-edit/wp-edit-mode-state.service";

angular
  .module('openproject.workPackages.controllers')
  .controller('WorkPackageDetailsController', WorkPackageDetailsController);

function WorkPackageDetailsController($scope,
                                      $state,
                                      $rootScope,
                                      I18n,
                                      PathHelper,
                                      UsersHelper,
                                      WorkPackageService,
                                      NotificationsService,
                                      wpEditModeState:WorkPackageEditModeStateService,
                                      wpCacheService) {

  $scope.wpEditModeState = wpEditModeState;

  // TODO This is an ugly hack since most of this controller relies on the old HALAPIResource.
  // We should move all that to the new WorkPackageResource.
  scopedObservable($scope, wpCacheService.loadWorkPackage($state.params.workPackageId))
    .subscribe((wp:WorkPackageResource) => {
      $scope.workPackageResource = wp;
      wp.schema.$load();
    });

  $scope.initializedWorkPackage = WorkPackageService.getWorkPackage($state.params.workPackageId)
    .then(function (workPackage) {
      return init(workPackage);
    });

  function init(workPackage) {

    var refreshRequiredFunction = $rootScope.$on('workPackageRefreshRequired', function () {
      refreshWorkPackage();
    });
    $scope.$on('$destroy', refreshRequiredFunction);

    // initialization
    setWorkPackageScopeProperties(workPackage);

    $scope.I18n = I18n;
    WorkPackageService.cache().put('preselectedWorkPackageId', $scope.workPackage.props.id);
    $scope.maxDescriptionLength = 800;

    // expose to child controllers
    $scope.outputMessage = outputMessage;
    $scope.outputError = outputError;

    // toggles
    $scope.toggleStates = {
      hideFullDescription: true,
      hideAllAttributes: true
    };

    $scope.focusAnchorLabel = getFocusAnchorLabel(
      $state.current.url.replace(/\//, ''),
      $scope.workPackage
    );
  }

  function refreshWorkPackage() {
    WorkPackageService.getWorkPackage($scope.workPackage.props.id)
      .then(function (workPackage) {
        setWorkPackageScopeProperties(workPackage);
        $scope.$broadcast('workPackageRefreshed');
      });
  }

  function outputMessage(message, isError) {
    if (!!isError) {
      NotificationsService.addError(message);
    }
    else {
      NotificationsService.addSuccess(message);
    }
  }

  function outputError(error) {
    outputMessage(error.message || I18n.t('js.work_packages.error.general'), true);
  }

  function setWorkPackageScopeProperties(workPackage) {
    $scope.workPackage = workPackage;
    $scope.displayWatchButton = workPackage.links.hasOwnProperty('unwatch') ||
      workPackage.links.hasOwnProperty('watch');

    // watchers
    if (workPackage.links.watchers) {
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

  }

  $scope.canViewWorkPackageWatchers = function () {
    return !!($scope.workPackage && $scope.workPackage.embedded.watchers !== undefined);
  };

  $scope.onWorkPackageSave = function () {
    $rootScope.$emit('workPackagesRefreshInBackground');
  };

  function getFocusAnchorLabel(tab, workPackage) {
    var tabLabel = I18n.t('js.work_packages.tabs.' + tab),
      params = {
        tab: tabLabel,
        type: workPackage.embedded.type.props.name,
        subject: workPackage.props.subject
      };

    return I18n.t('js.label_work_package_details_you_are_here', params);
  }
}
