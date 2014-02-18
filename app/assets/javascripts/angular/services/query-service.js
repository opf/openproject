angular.module('openproject.services')

.service('QueryService', ['$http', 'PathHelper', function($http, PathHelper){
  QueryService = {
    getWorkPackages: function(projectId, query) {
      var url = projectId ? PathHelper.projectWorkPackagesPath(projectId) : PathHelper.workPackagesPath();

      var params =  {
        'c[]': query.selectedColumns.map(function(column){
          return column.name;
        }),
        'group_by': query.group_by
      };

      return $http({
          method: 'GET',
          url: url,
          params: params,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'
        }}).then(function(response){
          return response.data;
        });
    }
  };

  return QueryService;
}]);
