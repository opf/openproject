angular.module('openproject.services')

.constant('DEFAULT_FILTER_PARAMS', {'fields[]': 'status_id', 'operators[status_id]': 'o'})

.service('WorkPackageService', ['$http', 'PathHelper', 'WorkPackagesHelper', 'DEFAULT_FILTER_PARAMS', function($http, PathHelper, WorkPackagesHelper, DEFAULT_FILTER_PARAMS) {

  var WorkPackageService = {
    getWorkPackagesByQueryId: function(projectIdentifier, queryId) {
      var url = projectIdentifier ? PathHelper.apiProjectWorkPackagesPath(projectIdentifier) : PathHelper.apiWorkPackagesPath();

      var params = queryId ? { query_id: queryId } : DEFAULT_FILTER_PARAMS;

      return WorkPackageService.doQuery(url, params);
    },

    getWorkPackages: function(projectIdentifier, query, paginationOptions) {
      var url = projectIdentifier ? PathHelper.apiProjectWorkPackagesPath(projectIdentifier) : PathHelper.apiWorkPackagesPath();
      var params = angular.extend(query.toParams(), {
        page: paginationOptions.page,
        per_page: paginationOptions.perPage
      });

      return WorkPackageService.doQuery(url, params);
    },

    loadWorkPackageColumnsData: function(workPackages, columnNames) {
      var url = PathHelper.apiWorkPackagesColumnDataPath();

      var params = {
        'ids[]': workPackages.map(function(workPackage){
          return workPackage.id;
        }),
        'column_names[]': columnNames
      };

      return WorkPackageService.doQuery(url, params);
    },

    // Note: Should this be on a project-service?
    getWorkPackagesSums: function(projectIdentifier, columns){
      var columnNames = columns.map(function(column){
        return column.name;
      });

      var url = PathHelper.apiWorkPackagesSumsPath(projectIdentifier);

      var params = {
        'column_names[]': columnNames
      };

      return WorkPackageService.doQuery(url, params);
    },

    augmentWorkPackagesWithColumnsData: function(workPackages, columns) {
      var columnNames = columns.map(function(column) {
        return column.name;
      });

      return WorkPackageService.loadWorkPackageColumnsData(workPackages, columnNames)
        .then(function(data){
          var columnsData = data.columns_data;
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
