// global
angular.module('openproject.services', ['openproject.uiComponents']);
angular.module('openproject.helpers', ['openproject.services']);
angular.module('openproject.models', []);

// timelines
angular.module('openproject.timelines', ['openproject.timelines.controllers', 'openproject.timelines.directives', 'openproject.uiComponents']);
angular.module('openproject.timelines.models', ['openproject.helpers']);
angular.module('openproject.timelines.helpers', []);
angular.module('openproject.timelines.controllers', ['openproject.timelines.models']);
angular.module('openproject.timelines.services', ['openproject.timelines.models', 'openproject.timelines.helpers']);
angular.module('openproject.timelines.directives', ['openproject.timelines.models', 'openproject.timelines.services', 'openproject.uiComponents', 'openproject.helpers']);

// work packages
angular.module('openproject.workPackages', ['openproject.workPackages.controllers', 'openproject.workPackages.filters', 'openproject.workPackages.directives', 'openproject.uiComponents']);
angular.module('openproject.workPackages.helpers', ['openproject.helpers']);
angular.module('openproject.workPackages.filters', ['openproject.workPackages.helpers']);
angular.module('openproject.workPackages.controllers', ['openproject.models', 'openproject.workPackages.helpers', 'openproject.services']);
angular.module('openproject.workPackages.directives', ['openproject.helpers', 'openproject.workPackages.helpers', 'openproject.services']);

// main app
var openprojectApp = angular.module('openproject', ['ui.select2', 'ui.date', 'openproject.uiComponents', 'openproject.timelines', 'openproject.workPackages', 'ngAnimate']);

openprojectApp
  .config(['$locationProvider', '$httpProvider', function($locationProvider, $httpProvider) {
    $locationProvider.html5Mode(true);
    $httpProvider.defaults.headers.common['X-CSRF-TOKEN'] = jQuery('meta[name=csrf-token]').attr('content'); // TODO find a more elegant way to keep the session alive
  }])
  .run(['$http', function($http){
    $http.defaults.headers.common.Accept = 'application/json';
  }]);
