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

openprojectApp.config(['$stateProvider', '$urlRouterProvider',
  function($stateProvider, $urlRouterProvider) {

  $urlRouterProvider.otherwise("/wp");

  $stateProvider
    .state('work-packages', {
      url: "/wp",
      abstract: true,
      templateUrl: "/templates/work_packages.html"
    })
    .state('work-packages.list', {
      url: "",
      templateUrl: "/templates/work_packages.list.html",
      controller: function($scope) {
        //
      }
    })
    .state('work-packages.list.details', {
      url: "/:workPackageId",
      templateUrl: "/templates/work_packages.list.details.html",
      controller: ['$scope', '$stateParams',
        function($scope, $stateParams) {
          $scope.workPackageId = $stateParams.workPackageId

          $scope.$watch('rows', function(rows){
            if (rows && rows.length > 0) {
              var row = $scope.rows.find(function(row) {
                return row.object.id == $scope.workPackageId;
              });
              $scope.workPackage = row ? row.object : {};
            }
          });

        }]
    })
}]);
