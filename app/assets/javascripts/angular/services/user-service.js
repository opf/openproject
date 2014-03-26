//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

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
