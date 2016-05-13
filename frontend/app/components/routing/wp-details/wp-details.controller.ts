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
angular
  .module('openproject.workPackages.controllers')
  .controller('WorkPackageDetailsController', WorkPackageDetailsController);

function WorkPackageDetailsController($scope,
                                      $state,
                                      workPackage,
                                      I18n,
                                      RELATION_TYPES,
                                      RELATION_IDENTIFIERS,
                                      $q,
                                      $rootScope,
                                      WorkPackagesHelper,
                                      PathHelper,
                                      UsersHelper,
                                      WorkPackageService,
                                      CommonRelationsHandler,
                                      ChildrenRelationsHandler,
                                      ParentRelationsHandler,
                                      NotificationsService,
                                      wpCacheService) {

  var refreshRequiredFunction = $rootScope.$on('workPackageRefreshRequired', function () {
    refreshWorkPackage();
  });
  $scope.$on('$destroy', refreshRequiredFunction);

  // TODO This is an ugly hack since most of this controller relies on the old HALAPIResource.
  // We should move all that to the new WorkPackageResource.
  scopedObservable($scope, wpCacheService.loadWorkPackage(workPackage.props.id))
    .subscribe((wp: WorkPackageResource) => {
      $scope.workPackageResource = wp;
      wp.schema.$load();
    });

  // initialization
  setWorkPackageScopeProperties(workPackage);

  $scope.I18n = I18n;
  WorkPackageService.cache().put('preselectedWorkPackageId', $scope.workPackage.props.id);
  $scope.maxDescriptionLength = 800;

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
    outputMessage(error.message || I18n.t('js.work_packages.error'), true);
  }

  // expose to child controllers
  $scope.outputMessage = outputMessage;
  $scope.outputError = outputError;

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

    // relations
    $q.all(WorkPackagesHelper.getParent(workPackage)).then(function (parents) {
      var relationsHandler = new ParentRelationsHandler(workPackage, parents, 'parent');
      $scope.wpParent = relationsHandler;
    });

    $q.all(WorkPackagesHelper.getChildren(workPackage)).then(function (children) {
      var relationsHandler = new ChildrenRelationsHandler(workPackage, children);
      $scope.wpChildren = relationsHandler;
    });

    function relationTypeIterator(key) {
      $q.all(WorkPackagesHelper.getRelationsOfType(
        workPackage,
        RELATION_TYPES[key])
      ).then(function (relations) {
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

  $scope.canViewWorkPackageWatchers = function () {
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
