// timelines
angular.module('openproject.timelines', ['openproject.timelines.controllers', 'openproject.timelines.directives', 'openproject.uiComponents']);
angular.module('openproject.timelines.models', []);
angular.module('openproject.timelines.helpers', []);
angular.module('openproject.timelines.controllers', ['openproject.timelines.models']);
angular.module('openproject.timelines.services', ['openproject.timelines.models', 'openproject.timelines.helpers']);
angular.module('openproject.timelines.directives', ['openproject.timelines.models', 'openproject.timelines.services', 'openproject.uiComponents']);

// work packages
angular.module('openproject.workPackages', ['openproject.workPackages.controllers', 'openproject.workPackages.filters', 'openproject.workPackages.directives']);
angular.module('openproject.workPackages.helpers', ['openproject.uiComponents']);
angular.module('openproject.workPackages.filters', ['openproject.workPackages.helpers']);
angular.module('openproject.workPackages.controllers', ['openproject.workPackages.helpers']);
angular.module('openproject.workPackages.directives', ['openproject.uiComponents']);


// global
var openprojectApp = angular.module('openproject', ['ui.select2', 'openproject.uiComponents', 'openproject.timelines', 'openproject.workPackages']);

openprojectApp.config(['$locationProvider', function($locationProvider) {
  $locationProvider.html5Mode(true);
}]);
