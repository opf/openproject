timelinesApp.service('APIUrlHelper', [function() {
  APIUrlHelper = {
    apiPrefix: '/api/v2',
    projectsPath: function() {
      return APIUrlHelper.apiPrefix + '/projects';
    },
    projectPath: function(id) {
      return APIUrlHelper.projectsPath() + '/' + id;
    },
    projectTypesPath: function() {
      return APIUrlHelper.apiPrefix + '/project_types';
    },
    projectTypePath: function(id) {
      return APIUrlHelper.projectTypesPath() + '/' + id;
    },
    planningElementTypesPath: function() {
      return APIUrlHelper.apiPrefix + '/planning_element_types';
    },
    planningElementTypePath: function(id) {
      return APIUrlHelper.planningElementTypesPath() + '/' + id;
    },
    statusesPath: function() {
      return APIUrlHelper.apiPrefix + '/statuses';
    },
    statusPath: function(id) {
      return APIUrlHelper.statusesPath() + '/' + id;
    },
    colorsPath: function() {
      return APIUrlHelper.apiPrefix + '/colors';
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
