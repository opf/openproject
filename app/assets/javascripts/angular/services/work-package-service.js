angular.module('openproject.services')

.service('WorkPackageService', ['$http', 'PathHelper', 'WorkPackagesHelper', function($http, PathHelper, WorkPackagesHelper) {

  var WorkPackageService = {
    getWorkPackages: function(projectId, query) {
      var url = projectId ? PathHelper.projectWorkPackagesPath(projectId) : PathHelper.workPackagesPath();

      return WorkPackageService.doQuery(url, query.toParams());
    },

    loadWorkPackageColumnsData: function(workPackages, columnNames, errorHanlder) {
      var url = PathHelper.workPackagesColumnDataPath();

      var params = {
        'ids[]': workPackages.map(function(workPackage){
          return workPackage.id;
        }),
        'column_names[]': columnNames
      };

      return WorkPackageService.doQuery(url, params, errorHanlder);
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

    augmentWorkPackagesWithColumnsData: function(workPackages, columns, errorHanlder) {
      var columnNames = columns.map(function(column){
        return column.name;
      });

      return WorkPackageService.loadWorkPackageColumnsData(workPackages, columnNames, errorHanlder)
        .then(function(columnsData){
          angular.forEach(workPackages, function(workPackage, i) {
            angular.forEach(columns, function(column, j){
              WorkPackagesHelper.augmentWorkPackageWithData(workPackage, column.name, !!column.custom_field, columnsData[j][i]);
            });
          });

          return workPackages;
        });
    },

    doQuery: function(url, params, errorHanlder) {
      return $http({
        method: 'GET',
        url: url,
        params: params,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
      }).error(function(data, status, headers, config){
        return errorHanlder.call(this, data);
      }).then(function(response){
        return response.data;
      });
    }
  };

  return WorkPackageService;
}]);
