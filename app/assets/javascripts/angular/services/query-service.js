angular.module('openproject.services')

.service('QueryService', ['$http', 'PathHelper', function($http, PathHelper){
  QueryService = {
    getWorkPackages: function(projectId, query) {
      var url = projectId ? PathHelper.projectWorkPackagesPath(projectId) : PathHelper.workPackagesPath();

      return $http({
          method: 'GET',
          url: url,
          params: query,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'
        }}).then(function(response){
          return response.data;
        });
    }
  };

  return QueryService;
}]);
