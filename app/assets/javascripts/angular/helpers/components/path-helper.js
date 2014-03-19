// TODO forward rails routes
angular.module('openproject.helpers')

.service('PathHelper', [function() {
  PathHelper = {
    apiPrefix: '/api/v2',

    projectPath: function(projectIdentifier) {
      return '/api/v2/projects/' + projectIdentifier;
    },
    workPackagesPath: function() {
      return '/planning_elements';
    },
    workPackagePath: function(id) {
      return '/work_packages/' + id;
    },
    projectWorkPackagesPath: function(projectIdentifier) {
      return PathHelper.projectPath(projectIdentifier) + PathHelper.workPackagesPath() + ".json";
    },
    usersPath: function() {
      return '/users';
    },
    userPath: function(id) {
      return PathHelper.usersPath() + id;
    },
    workPackagesColumnDataPath: function() {
      return PathHelper.workPackagesPath() + '/column_data';
    },
    workPackagesSumsPath: function(projectIdentifier) {
      return PathHelper.projectPath(projectIdentifier) + '/column_sums';
    },
    versionPath: function(versionId) {
      return '/versions/' + versionId;
    },
    statusesPath: function() {
      return '/statuses'
    }
  };

  return PathHelper;
}]);
