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

module.exports = function($scope, $state, $stateParams, QueryService, PathHelper, $rootScope) {

  // Setup
  $scope.$state = $state;
  $scope.selectedTitle = I18n.t('js.toolbar.unselected_title');

  if ($stateParams.projectPath.indexOf(PathHelper.staticBase + '/projects') === 0) {
    $scope.projectIdentifier = $stateParams.projectPath.replace(PathHelper.staticBase + '/projects/', '');
  }

  $scope.query_id = $stateParams.query_id;

  $scope.$watch(QueryService.getAvailableGroupedQueries, function(availableQueries) {
    if (availableQueries) {
      $scope.groups = [{ name: I18n.t('js.label_global_queries'), models: availableQueries['queries']},
                       { name: I18n.t('js.label_custom_queries'), models: availableQueries['user_queries']}];
    }
  });

  $scope.isDetailsViewActive = function() {
    return $state.includes('work-packages.list.details');
  };

  $scope.getToggleActionLabel = function(active) {
    return (active) ? I18n.t('js.label_deactivate') : I18n.t('js.label_activate');
  };

  $scope.getActivationActionLabel = function(activate) {
    return (activate) ? I18n.t('js.label_activate') : '';
  };
  $rootScope.$broadcast('openproject.layout.activateMenuItem');
};
