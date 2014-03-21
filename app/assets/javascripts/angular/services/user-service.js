angular.module('openproject.services')

.service('UserService', ['$http', 'PathHelper', 'FunctionDecorators', function($http, PathHelper, FunctionDecorators) {
  var registeredUserIds = [], cachedUsers = {};

  UserService = {
    getUsers: function() {
      var url = PathHelper.apiUsersPath();

      return UserService.doQuery(url);
    },

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
      if(!params) {
        // TODO find out which scope we want to apply here
        params = {status: 'all'};
      }

      return $http.get(url, { params: params })
        .then(function(response){
          return response.data.users;
        });
    }

  };

  return UserService;
}]);
