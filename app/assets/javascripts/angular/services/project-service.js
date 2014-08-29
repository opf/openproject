angular.module('openproject.services')

.service('ProjectService', ['$http', 'PathHelper', 'FiltersHelper', function($http, PathHelper, FiltersHelper) {

  var ProjectService = {
    getProject: function(projectIdentifier) {
      var url = PathHelper.apiProjectPath(projectIdentifier);

      return $http.get(url).then(function(response) {
        return response.data.project;
      });
    },

    getProjects: function() {
      var url = PathHelper.apiProjectsPath();

      return ProjectService.doQuery(url)
        .then(function(projects){
          return FiltersHelper.assignAncestorLevels(projects);
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
