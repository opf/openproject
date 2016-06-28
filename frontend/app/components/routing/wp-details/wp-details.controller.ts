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
import {WorkPackageEditModeStateService} from "../../wp-edit/wp-edit-mode-state.service";

angular
  .module('openproject.workPackages.controllers')
  .controller('WorkPackageDetailsController', WorkPackageDetailsController);

function WorkPackageDetailsController($scope,
                                      $state,
                                      $rootScope,
                                      $q,
                                      I18n,
                                      PathHelper,
                                      WorkPackageService,
                                      NotificationsService,
                                      wpEditModeState:WorkPackageEditModeStateService,
                                      wpCacheService) {

  $scope.wpEditModeState = wpEditModeState;
  $scope.I18n = I18n;
  $scope.initializedWorkPackage = $q.defer();

  scopedObservable($scope, wpCacheService.loadWorkPackage($state.params.workPackageId))
    .subscribe((wp:WorkPackageResource) => {
      $scope.workPackageResource = wp;

      wp.schema.$load();
      WorkPackageService.cache().put('preselectedWorkPackageId', wp.id);

      $scope.focusAnchorLabel = getFocusAnchorLabel(
        $state.current.url.replace(/\//, ''),
        wp
      );

      $scope.initializedWorkPackage.resolve();
    });

  $scope.onWorkPackageSave = function () {
    $rootScope.$emit('workPackagesRefreshInBackground');
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
