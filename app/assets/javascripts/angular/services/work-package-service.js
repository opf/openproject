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

angular.module('openproject.services')

.service('WorkPackageService', ['$http', 'PathHelper', 'WorkPackagesHelper', function($http, PathHelper, WorkPackagesHelper) {

  var WorkPackageService = {
    getWorkPackages: function(projectId, query, paginationOptions) {
      var url = projectId ? PathHelper.projectWorkPackagesPath(projectId) : PathHelper.workPackagesPath();
      var params = angular.extend(query.toParams(), {
        page: paginationOptions.page,
        per_page: paginationOptions.perPage
      });

      return WorkPackageService.doQuery(url, params);
    },

    loadWorkPackageColumnsData: function(workPackages, columnNames) {
      var url = PathHelper.workPackagesColumnDataPath();

      var params = {
        'ids[]': workPackages.map(function(workPackage){
          return workPackage.id;
        }),
        'column_names[]': columnNames
      };

      return WorkPackageService.doQuery(url, params);
    },

    // Note: Should this be on a project-service?
    getWorkPackagesSums: function(projectId, columns){
      var columnNames = columns.map(function(column){
        return column.name;
      });

      var url = PathHelper.workPackagesSumsPath(projectId);

      var params = {
        'column_names[]': columnNames
      };

      return WorkPackageService.doQuery(url, params);
    },

    augmentWorkPackagesWithColumnsData: function(workPackages, columns) {
      var columnNames = columns.map(function(column){
        return column.name;
      });

      return WorkPackageService.loadWorkPackageColumnsData(workPackages, columnNames)
        .then(function(columnsData){
          angular.forEach(workPackages, function(workPackage, i) {
            angular.forEach(columns, function(column, j){
              WorkPackagesHelper.augmentWorkPackageWithData(workPackage, column.name, !!column.custom_field, columnsData[j][i]);
            });
          });

          return workPackages;
        });
    },

    doQuery: function(url, params) {
      return $http({
        method: 'GET',
        url: url,
        params: params,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
      }).then(function(response){
        return response.data;
      });
    }
  };

  return WorkPackageService;
}]);
