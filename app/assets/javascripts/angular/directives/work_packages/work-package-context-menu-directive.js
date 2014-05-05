angular.module('openproject.workPackages.directives')

.directive('workPackageContextMenu', [function() {
  return {
    restrict: 'EA',
    replace: true,
    scope: {},
    templateUrl: '/templates/work_packages/work_package_context_menu.html',
    link: function(scope, element, attrs) {
    }
  };
}]);
