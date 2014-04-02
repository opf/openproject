angular.module('openproject.services')

.service('UserService', ['$http', 'PathHelper', 'WorkPackageLoadingHelper', function($http, PathHelper, WorkPackageLoadingHelper) {
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

    registerUserId: function(id) {
      var user = cachedUsers[id];
      if (user) return user;

      registeredUserIds.push(id);
      cachedUsers[id] = { name: '', firstname: '', lastname: '' }; // create an empty object and fill its values on load

      WorkPackageLoadingHelper.withDelay(10, UserService.loadRegisteredUsers); // HACK
      // TODO hook into a given promise chain to post-load user data, or if ngView is used trigger load on $viewContentLoaded

      return cachedUsers[id];
    },

    loadRegisteredUsers: function() {
      if (registeredUserIds.length > 0) {
        return UserService.doQuery(PathHelper.apiUsersPath(), { 'ids[]': registeredUserIds })
          .then(function(users){
            UserService.storeUsers(users);
            return cachedUsers;
          });
      }
    },

    storeUsers: function(users) {
      // writes user data to object stubs providing a mechanism for wiring up user data to the scope
      angular.forEach(users, function(user) {
        var cachedUser = cachedUsers[user.id];

        cachedUser.firstname = user.firstname;
        cachedUser.lastname = user.lastname;
        cachedUser.name = user.name;
      });
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
