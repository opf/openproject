angular.module('openproject.services')

.service('StatusService', ['$http', 'PathHelper', function($http, PathHelper) {

  var StatusService = {
    getStatuses: function(projectIdentifier) {
      var url;

      if(projectIdentifier) {
        url = PathHelper.apiProjectStatusesPath(projectIdentifier);
      } else {
        url = PathHelper.apiStatusesPath();
      }

      return StatusService.doQuery(url);
    },

    doQuery: function(url, params) {
      return $http.get(url, { params: params })
        .then(function(response){
          return response.data.statuses;
        });
    }
  };

  return StatusService;
}]);
