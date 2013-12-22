timelinesApp.service('APIUrlHelper', [function() {
  APIUrlHelper = {
    apiPrefix: '/api/v2',
    projectsPath: function() {
      return APIUrlHelper.apiPrefix + '/projects';
    },
    projectPath: function(projectId) {
      return APIUrlHelper.projectsPath() + '/' + projectId;
    },
    projectReportingsPath: function(projectId) {
      return APIUrlHelper.projectPath(projectId) + '/reportings';
    },
    projectsPlanningElementsPath: function(projectIds) {
      return APIUrlHelper.projectPath(projectIds.join(',')) + '/planning_elements';
    },
    projectsPlanningElementPath: function(projectIds, id) {
      return APIUrlHelper.projectsPlanningElementsPath(projectIds) + '/' + id;
    }
  };

  return APIUrlHelper;
}]);
