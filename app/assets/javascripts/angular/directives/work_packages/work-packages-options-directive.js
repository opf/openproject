angular.module('openproject.workPackages.directives')

.directive('workPackagesOptions', ['I18n', function(I18n){
  return {
    restrict: 'E',
    templateUrl: '/templates/work_packages/work_packages_options.html',
    link: function(scope, element, attributes) {
    }
  };
}]);
