// TODO move to UI components
angular.module('openproject.uiComponents')

.directive('workPackageColumn', ['PathHelper', 'WorkPackagesHelper', function(PathHelper, WorkPackagesHelper){
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      workPackage: '=',
      column: '='
    },
    templateUrl: '/templates/components/work_package_column.html',
    link: function(scope, element, attributes) {
      var defaultText = '';

      // Set text to be displayed
      scope.displayText = WorkPackagesHelper.getRowObjectContent(scope.workPackage, scope.column.name) || defaultText;

      switch (scope.column.name){
        case 'subject':
          scope.url = PathHelper.workPackagePath(scope.workPackage.id);
          break;
        case 'assigned_to':
          if (scope.workPackage.assigned_to) scope.url = PathHelper.userPath(scope.workPackage.assigned_to.id);
          break;
      }

    }
  };
}]);
