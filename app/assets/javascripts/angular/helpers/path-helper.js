// TODO forward rails routes
angular.module('openproject.uiComponents')

.service('PathHelper', [function() {
  PathHelper = {
    workPackagesPath: function() {
      return '/work_packages';
    },
    workPackagePath: function(id) {
      return '/work_packages/' + id;
    },
    projectWorkPackagesPath: function(projectIdentifier) {
      return '/projects/' + projectIdentifier + PathHelper.workPackagesPath();
    },
    userPath: function(id) {
      return '/users/' + id;
    }
  };

  return PathHelper;
}]);
