//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

angular.module('openproject.workPackages.directives')

.directive('costEntry', ['PathHelper', 'CostTypeService', function(PathHelper, CostTypeService) {
  return {
    restrict: 'E',
    trasclude: true,
    templateUrl: '/templates/plugin-costs/work_packages/cost_entry.html',
    scope: {
      workPackage: "=",
      costEntry: "="
    },
    controller: function($scope) {
      $scope.spentUnits = $scope.costEntry.props.spentUnits;

      CostTypeService.getCostType($scope.costEntry.links.costType.props.href)
        .then(function(costType) {

        $scope.costType = costType;

        setUnitName();

        setLink();
      });

      var setUnitName = function() {
        if ($scope.spentUnits === "1") {
          $scope.unit = $scope.costType.props.unit;
        }
        else {
          $scope.unit = $scope.costType.props.unitPlural;
        }
      };

      var setLink = function() {
        var link = PathHelper.staticWorkPackagePath($scope.workPackage.props.id);

        link += '/cost_entries?cost_type_id=' + $scope.costType.props.id;
        link += '&project_id=' + $scope.workPackage.embedded.project.props.id;

        $scope.summaryLink = link;
      };
    }
  };
}]);
