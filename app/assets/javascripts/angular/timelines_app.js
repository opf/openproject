var timelinesApp = angular.module('openproject.timelines', ['ui.select2', 'ngResource'])

.run(['$http', function($http){
  $http.defaults.headers.common.Accept = 'application/json';
}]);
