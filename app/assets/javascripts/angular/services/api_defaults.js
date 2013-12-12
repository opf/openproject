timelinesApp.service('APIDefaults', [function() {
  APIDefaults = {
    apiPrefix: '/api/v2',
    projectPath: '/projects/:projectId'
  };

  return APIDefaults;
}]);
