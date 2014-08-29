window.openProject = new OpenProject({
  urlRoot : '/',
  loginUrl: '/fake-login'
});

window.$injector = angular.injector(['ng', 'ngMock', 'openproject.uiComponents', 'openproject.timelines.models', 'openproject.models', 'openproject.services']);
