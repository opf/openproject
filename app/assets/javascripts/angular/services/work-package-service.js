angular.module('openproject.services')

.service('WorkPackageService', ['$http', 'PathHelper', 'WorkPackagesHelper', function($http, PathHelper, WorkPackagesHelper) {

  var WorkPackageService = {
    getWorkPackages: function(projectId, query, errorHandler) {
      var url = projectId ? PathHelper.projectWorkPackagesPath(projectId) : PathHelper.workPackagesPath();

      return WorkPackageService.doQuery(url, query.toParams(), errorHandler);
    },

    loadWorkPackageColumnsData: function(workPackages, columnNames, errorHandler) {
      var url = PathHelper.workPackagesColumnDataPath();

      var params = {
        'ids[]': workPackages.map(function(workPackage){
          return workPackage.id;
        }),
        'column_names[]': columnNames
      };

      return WorkPackageService.doQuery(url, params, errorHandler);
    },

    // Note: Should this be on a project-service?
    getWorkPackagesSums: function(projectId, columns, errorHandler){
      var columnNames = columns.map(function(column){
        return column.name;
      });

      var url = PathHelper.workPackagesSumsPath(projectId);

      var params = {
        'column_names[]': columnNames
      };

      return WorkPackageService.doQuery(url, params, errorHandler);
    },

    augmentWorkPackagesWithColumnsData: function(workPackages, columns, errorHandler) {
      var columnNames = columns.map(function(column){
        return column.name;
      });

      return WorkPackageService.loadWorkPackageColumnsData(workPackages, columnNames, errorHandler)
        .then(function(columnsData){
          angular.forEach(workPackages, function(workPackage, i) {
            angular.forEach(columns, function(column, j){
              WorkPackagesHelper.augmentWorkPackageWithData(workPackage, column.name, !!column.custom_field, columnsData[j][i]);
            });
          });

          return workPackages;
        });
    },

    doQuery: function(url, params, errorHandler) {
      return $http({
        method: 'GET',
        url: url,
        params: params,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
      }).error(function(data, status, headers, config){
        return errorHandler.call(this, data);
      }).then(function(response){
        return response.data;
      });
    }
  };

  return WorkPackageService;
}]);
