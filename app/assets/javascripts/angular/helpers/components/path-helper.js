// TODO forward rails routes
angular.module('openproject.helpers')

.service('PathHelper', [function() {
  PathHelper = {
    apiPrefix: '/api/v2',
    apiPrefixV3: '/api/v3',

    projectPath: function(projectIdentifier) {
      return '/projects/' + projectIdentifier;
    },
    workPackagesPath: function() {
      return '/work_packages';
    },
    workPackagePath: function(id) {
      return '/work_packages/' + id;
    },
    usersPath: function() {
      return '/users';
    },
    userPath: function(id) {
      return PathHelper.usersPath() + id;
    },
    versionPath: function(versionId) {
      return '/versions/' + versionId;
    },
    apiProjectPath: function(projectIdentifier) {
      return PathHelper.apiPrefixV3 + PathHelper.projectPath(projectIdentifier);
    },
    apiWorkPackagesPath: function() {
      return PathHelper.apiPrefixV3 + '/work_packages';
    },
    apiProjectWorkPackagesPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + PathHelper.workPackagesPath();
    },
    apiAvailableColumnsPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + '/queries/available_columns';
    },
    apiWorkPackagesColumnDataPath: function() {
      return PathHelper.apiWorkPackagesPath() + '/column_data';
    },
    apiPrioritiesPath: function() {
      return PathHelper.apiPrefix + '/planning_element_priorities';
    },
    apiStatusesPath: function() {
      return PathHelper.apiPrefix + '/statuses';
    },
    apiProjectStatusesPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + '/statuses';
    },
    apiTypesPath: function() {
      return PathHelper.apiPrefix + '/planning_element_types';
    },
    apiProjectTypesPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + '/planning_element_types';
    },
    apiUsersPath: function() {
      return PathHelper.apiPrefix + PathHelper.usersPath();
    },
    apiWorkPackagesSumsPath: function(projectIdentifier) {
      return PathHelper.apiProjectPath(projectIdentifier) + PathHelper.workPackagesPath() + '/column_sums';
    },
  };

  return PathHelper;
}]);
