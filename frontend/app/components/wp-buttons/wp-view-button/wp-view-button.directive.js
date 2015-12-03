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

angular
  .module('openproject.workPackages.directives')
  .directive('wpViewButton', wpViewButton);

function wpViewButton() {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-buttons/wp-view-button/wp-view-button.directive.html',

    controller: WorkPackageViewButtonController
  };
}

function WorkPackageViewButtonController($scope, $state, $location, loadingIndicator) {
  $scope.isShowViewActive = function() {
    return $state.includes('work-packages.show');
  };

  $scope.label = $scope.getActivationActionLabel(!$scope.isShowViewActive())
      + I18n.t('js.button_show_view');

  if ($scope.isShowViewActive()) {
    $scope.accessKey = 9;
  }

  $scope.showWorkPackageShowView = function() {
    var promise;

    if ($state.is('work-packages.list.new') && $state.params.type) {
      promise = $state.go('work-packages.new', $state.params);

    } else {
      var id = $state.params.workPackageId || $scope.preselectedWorkPackageId ||
          $scope.nextAvailableWorkPackage(), queryProps = $location.search()['query_props'];

      promise = $state.go('work-packages.show.activity', {
        projectPath: $scope.projectIdentifier || '',
        workPackageId: id,
        'query_props': queryProps
      });
    }

    loadingIndicator.on(promise);
  };
}
