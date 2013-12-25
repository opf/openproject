var timelinesApp = angular.module('openproject.timelines', ['ui.select2'])

.run(['$http', function($http){
  $http.defaults.headers.common.Accept = 'application/json';
}]);
