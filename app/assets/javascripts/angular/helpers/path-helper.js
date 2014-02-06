// TODO forward rails routes

openprojectApp.service('PathHelper', [function() {
  PathHelper = {
    projectWorkPackagesPath: function(projectIdentifier) {
      return '/projects/' + projectIdentifier + '/work_packages';
    }
  };

  return PathHelper;
}]);
