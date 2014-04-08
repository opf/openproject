angular.module('openproject.services')

.service('ProjectService', ['$http', '$q', 'PathHelper', 'FiltersHelper', function($http, $q, PathHelper, FiltersHelper) {

  var ProjectService = {
    getProject: function(projectIdentifier) {
      var url = PathHelper.apiV3ProjectPath(projectIdentifier);

      return ProjectService.doQuery(url);
    },

    getProjects: function() {
      var url = PathHelper.apiV3ProjectsPath();

      return ProjectService.doQuery(url)
        .then(function(projects){
          return $q.when(FiltersHelper.assignAncestorLevels(projects));
        });
    },

    getSubProjects: function(projectIdentifier) {
      var url = PathHelper.apiProjectSubProjectsPath(projectIdentifier);

      return ProjectService.doQuery(url);
    },

    doQuery: function(url, params) {
      return $http.get(url, { params: params })
        .then(function(response){
          return response.data.projects;
        });
    },
  };

  return ProjectService;
}]);
