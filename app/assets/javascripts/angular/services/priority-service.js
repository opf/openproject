angular.module('openproject.services')

.service('PriorityService', ['$http', 'PathHelper', function($http, PathHelper) {

  var PriorityService = {
    getPriorities: function() {
      var url = PathHelper.apiPrioritiesPath();

      return PriorityService.doQuery(url);
    },

    doQuery: function(url, params) {
      return $http.get(url, { params: params })
        .then(function(response){
          return response.data.planning_element_priorities;
        });
    }
  };

  return PriorityService;
}]);
