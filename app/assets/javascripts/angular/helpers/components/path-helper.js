// TODO forward rails routes
angular.module('openproject.helpers')

.service('PathHelper', [function() {
  PathHelper = {
    apiPrefixV2: '/api/v2',
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
      return PathHelper.usersPath() + '/' + id;
    },
    versionsPath: function() {
      return '/versions';
    },
    versionPath: function(versionId) {
      return PathHelper.versionsPath() + '/' + versionId;
    },

    apiV2ProjectPath: function(projectIdentifier) {
      return PathHelper.apiPrefixV2 + PathHelper.projectPath(projectIdentifier);
    },
    apiV3ProjectPath: function(projectIdentifier) {
      return PathHelper.apiPrefixV3 + PathHelper.projectPath(projectIdentifier);
    },
    apiWorkPackagesPath: function() {
      return PathHelper.apiPrefixV3 + '/work_packages';
    },
    apiProjectWorkPackagesPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + PathHelper.workPackagesPath();
    },
    apiAvailableColumnsPath: function() {
      return PathHelper.apiPrefixV3 + '/queries/available_columns';
    },
    apiProjectAvailableColumnsPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + '/queries/available_columns';
    },
    apiWorkPackagesColumnDataPath: function() {
      return PathHelper.apiWorkPackagesPath() + '/column_data';
    },
    apiPrioritiesPath: function() {
      return PathHelper.apiPrefixV2 + '/planning_element_priorities';
    },
    apiStatusesPath: function() {
      return PathHelper.apiPrefixV2 + '/statuses';
    },
    apiProjectStatusesPath: function(projectIdentifier) {
      return PathHelper.apiV2ProjectPath(projectIdentifier) + '/statuses';
    },
    apiGroupsPath: function() {
      return PathHelper.apiPrefixV3 + '/groups';
    },
    apiRolesPath: function() {
      return PathHelper.apiPrefixV3 + '/roles';
    },
    apiWorkPackageTypesPath: function() {
      return PathHelper.apiPrefixV2 + '/planning_element_types';
    },
    apiProjectWorkPackageTypesPath: function(projectIdentifier) {
      return PathHelper.apiV2ProjectPath(projectIdentifier) + '/planning_element_types';
    },
    apiUsersPath: function() {
      return PathHelper.apiPrefixV2 + PathHelper.usersPath();
    },
    apiProjectVersionsPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + PathHelper.versionsPath();
    },
    apiProjectUsersPath: function(projectIdentifier) {
      return PathHelper.apiV2ProjectPath(projectIdentifier) + PathHelper.usersPath();
    },
    apiWorkPackagesSumsPath: function(projectIdentifier) {
      return PathHelper.apiV3ProjectPath(projectIdentifier) + PathHelper.workPackagesPath() + '/column_sums';
    },
  };

  return PathHelper;
}]);
