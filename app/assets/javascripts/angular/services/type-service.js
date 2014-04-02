angular.module('openproject.services')

.service('TypeService', ['$http', 'PathHelper', function($http, PathHelper) {

  var TypeService = {
    getTypes: function(projectIdentifier) {
      var url;

      if(projectIdentifier) {
        url = PathHelper.apiProjectWorkPackageTypesPath(projectIdentifier);
      } else {
        url = PathHelper.apiWorkPackageTypesPath();
      }


      return TypeService.doQuery(url);
    },

    doQuery: function(url, params) {
      return $http.get(url, { params: params })
        .then(function(response){
          return response.data.planning_element_types;
        });
    }
  };

  return TypeService;
}]);
