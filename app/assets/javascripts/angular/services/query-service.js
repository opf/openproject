angular.module('openproject.services')

.service('QueryService', ['$http', 'PathHelper', function($http, PathHelper) {

  var QueryService = {
    getAvailableColumns: function(projectId) {
      var url = PathHelper.availableColumnsPath(projectId);

      return QueryService.doQuery(url);
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

  return QueryService;
}]);
