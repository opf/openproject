var openprojectApp = angular.module('openproject', ['ui.select2', 'openproject.uiComponents']);

openprojectApp.config(['$locationProvider', function($locationProvider) {
  $locationProvider.html5Mode(true);
}]);
