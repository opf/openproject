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

module.exports = function($scope, WorkPackagesTableHelper, WorkPackageContextMenuHelper, WorkPackageService, WorkPackagesTableService, I18n, $window, PERMITTED_CONTEXT_MENU_ACTIONS) {

  $scope.I18n = I18n;

  $scope.$watch('row', function() {
    if (!$scope.row.checked) {
      WorkPackagesTableService.setCheckedStateForAllRows($scope.rows, false);
    }

    $scope.row.checked = true;
    $scope.permittedActions = WorkPackageContextMenuHelper.getPermittedActions(getSelectedWorkPackages(), PERMITTED_CONTEXT_MENU_ACTIONS);
  });

  $scope.isDetailsViewLinkPresent = function() {
    return !!angular.element('#work-package-context-menu li.open').length;
  };

  $scope.triggerContextMenuAction = function(action, link) {
    if (action === 'delete') {
      deleteSelectedWorkPackages();
    } else {
      $window.location.href = link;
    }
  };

  function deleteSelectedWorkPackages() {
    var rows = WorkPackagesTableHelper.getSelectedRows($scope.rows);

    WorkPackageService.performBulkDelete(getSelectedWorkPackages().map(function(wp) { return wp.id; }), true);
  }

  function getWorkPackagesFromSelectedRows() {
    var selectedRows = WorkPackagesTableHelper.getSelectedRows($scope.rows);

    return WorkPackagesTableHelper.getWorkPackagesFromRows(selectedRows);
  }

  function getSelectedWorkPackages() {
    var workPackagefromContext = $scope.row.object;
    var workPackagesfromSelectedRows = getWorkPackagesFromSelectedRows();

    if (workPackagesfromSelectedRows.length === 0) {
      return [workPackagefromContext];
    } else if (workPackagesfromSelectedRows.indexOf(workPackagefromContext) === -1) {
      return [workPackagefromContext].concat(workPackagesfromSelectedRows);
    } else {
      return workPackagesfromSelectedRows;
    }
  }

};
