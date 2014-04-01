angular.module('openproject.services')

.service('VersionService', ['$http', 'PathHelper', function($http, PathHelper) {

  var VersionService = {
    getProjectVersions: function(projectIdentifier) {
      var url = PathHelper.apiProjectVersionsPath(projectIdentifier);

      return VersionService.doQuery(url);
    },

    doQuery: function(url, params) {
      return $http.get(url, { params: params })
        .then(function(response){
          return response.data.versions;
        });
    }
  };

  return VersionService;
}]);
