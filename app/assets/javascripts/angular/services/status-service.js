angular.module('openproject.services')

.service('StatusService', ['$http', 'PathHelper', function($http, PathHelper) {

  var StatusService = {
    getStatuses: function() {
      var url = PathHelper.statusesPath();

      return WorkPackageService.doQuery(url);
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

  return StatusService;
}]);
