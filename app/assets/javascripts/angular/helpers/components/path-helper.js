// TODO forward rails routes
angular.module('openproject.uiComponents')

.service('PathHelper', [function() {
  PathHelper = {
    projectPath: function(projectIdentifier) {
      return '/projects/' + projectIdentifier;
    },
    workPackagesPath: function() {
      return '/work_packages';
    },
    workPackagePath: function(id) {
      return '/work_packages/' + id;
    },
    projectWorkPackagesPath: function(projectIdentifier) {
      return PathHelper.projectPath(projectIdentifier) + PathHelper.workPackagesPath();
    },
    userPath: function(id) {
      return '/users/' + id;
    },
    workPackagesColumnDataPath: function() {
      return PathHelper.workPackagesPath() + '/column_data';
    }
  };

  return PathHelper;
}]);
