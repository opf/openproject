angular.module('openproject.services')

.service('GroupService', ['$http', 'PathHelper', function($http, PathHelper) {

  var GroupService = {
    getGroups: function() {
      var url = PathHelper.apiGroupsPath();

      return GroupService.doQuery(url);
    },

    doQuery: function(url, params) {
      return $http.get(url, { params: params })
        .then(function(response){
          return response.data.groups;
        });
    }
  };

  return GroupService;
}]);
