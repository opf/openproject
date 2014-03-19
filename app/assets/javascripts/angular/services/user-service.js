angular.module('openproject.services')

.service('UserService', ['$http', 'PathHelper', 'FunctionDecorators', function($http, PathHelper, FunctionDecorators) {
  var registeredUserIds = [], cachedUsers = {};

  UserService = {
    registerUserId: function(id) {
      var user = cachedUsers[id];
      if (user) return user;

      registeredUserIds.push(id);
      cachedUsers[id] = { name: '', firstname: '', lastname: '' }; // create an empty object and fill its values on load

      FunctionDecorators.withDelay(10, UserService.loadRegisteredUsers); // HACK
      // TODO hook into a given promise chain to post-load user data, or if ngView is used trigger load on $viewContentLoaded

      return cachedUsers[id];
    },

    loadRegisteredUsers: function() {
      if (registeredUserIds.length > 0) {
        return $http.get(PathHelper.apiPrefix + PathHelper.usersPath(), {
          params: { 'ids[]': registeredUserIds }
        }).then(function(response){
          UserService.storeUsers(response.data.users);
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
    }
  };

  return UserService;
}]);
