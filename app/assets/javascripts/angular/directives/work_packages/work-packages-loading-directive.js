angular.module('openproject.workPackages.directives')

.directive('workPackagesLoading', ['I18n', function(I18n){

  return {
    restrict: 'E',
    templateUrl: '/templates/work_packages/work_packages_loading.html',
    scope: true,
    link: function(scope, element, attributes) {
    }
  };
}]);
