angular.module('openproject.services')

.service('UserService', ['$http', 'PathHelper', function($http, PathHelper) {
  var registeredUserIds = [], cachedUsers = {};

  UserService = {
    getUsers: function(projectIdentifier) {
      var url, params;

      if (projectIdentifier) {
        url = PathHelper.apiProjectUsersPath(projectIdentifier);
      } else {
        url = PathHelper.apiUsersPath();
        params = {status: 'all'};
      }

      return UserService.doQuery(url, params);
    },

    doQuery: function(url, params) {
      return $http.get(url, { params: params })
        .then(function(response){
          return response.data.users;
        });
    }

  };

  return UserService;
}]);
