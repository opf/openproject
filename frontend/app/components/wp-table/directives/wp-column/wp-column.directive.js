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
  .directive('wpColumn', wpColumn);

function wpColumn(){
  return {
    restrict: 'E',
    templateUrl: '/components/wp-table/directives/wp-column/wp-column.directive.html',
    replace: true,

    scope: {
      workPackage: '=',
      projectIdentifier: '=',
      column: '=',
      displayType: '@',
      displayEmpty: '@'
    },
    
    controller: WorkPackageColumnController
  };
}

function WorkPackageColumnController($scope, PathHelper, WorkPackagesHelper) {
  $scope.displayType = $scope.displayType || 'text';

  $scope.$watch(dataAvailable, setColumnData);

  function dataAvailable() {
    if (!$scope.workPackage) return false;

    if ($scope.column.custom_field) {
      return customValueAvailable();
    } else {
      return $scope.workPackage.hasOwnProperty($scope.column.name);
    }
  }

  function customValueAvailable() {
    var customFieldId = $scope.column.custom_field.id;

    return $scope.workPackage.custom_values &&
      $scope.workPackage.custom_values.filter(function(customValue){
        return customValue && customValue.custom_field_id === customFieldId;
      }).length;
  }

  function setColumnData() {
    setDisplayText(getFormattedColumnValue());

    if ($scope.column.meta_data.link.display) {
      displayDataAsLink(WorkPackagesHelper.getColumnDataId($scope.workPackage, $scope.column));
    } else {
      setCustomDisplayType();
    }
  }

  function getFormattedColumnValue() {
    if ($scope.column.custom_field) {
      var custom_field = $scope.column.custom_field;
      return WorkPackagesHelper.getFormattedCustomValue($scope.workPackage, custom_field);
    } else {
      return WorkPackagesHelper.getFormattedColumnData($scope.workPackage, $scope.column);
    }
  }

  function setDisplayText(value) {
    if (typeof value == 'number' || value){
      $scope.displayText = value;
    } else {
      $scope.displayText = $scope.displayEmpty || '';
    }
  }

  function setCustomDisplayType() {
    if ($scope.column.name === 'done_ratio') $scope.displayType = 'progress_bar';
  }

  function displayDataAsLink(id) {
    var linkMeta = $scope.column.meta_data.link;

    if (linkMeta.model_type === 'work_package') {
      var projectId = $scope.projectIdentifier || '';

      $scope.displayType = 'ref';
      $scope.stateRef = "work-packages.show.activity({projectPath: '" + projectId + "', workPackageId: " + id + "})";

    } else {
      $scope.displayType = 'link';
      $scope.url = getLinkFor(id, linkMeta);
    }
  }

  function getLinkFor(id, linkMeta){
    switch (linkMeta.model_type) {
      case 'user':
        if ($scope.workPackage[$scope.column.name] && $scope.workPackage[$scope.column.name].type == 'Group') {
          $scope.displayType = 'text';
          return '';
        } else {
          return PathHelper.staticUserPath(id);
        }
      case 'version':
        return PathHelper.staticVersionPath(id);
      case 'project':
        return PathHelper.staticProjectPath(id);
      default:
        return '';
    }
  }
}
