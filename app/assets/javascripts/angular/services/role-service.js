angular.module('openproject.services')

.service('RoleService', ['$http', 'PathHelper', function($http, PathHelper) {

  var RoleService = {
    getRoles: function() {
      var url = PathHelper.apiRolesPath();

      return RoleService.doQuery(url);
    },

    doQuery: function(url, params) {
      return $http.get(url, { params: params })
        .then(function(response){
          return response.data.roles;
        });
    }
  };

  return RoleService;
}]);
