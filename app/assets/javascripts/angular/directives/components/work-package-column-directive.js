// TODO move to UI components
angular.module('openproject.uiComponents')

.directive('workPackageColumn', ['PathHelper', function(PathHelper){
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      workPackage: '=',
      column: '='
    },
    templateUrl: '/templates/components/work_package_column.html',
    link: function(scope, element, attributes) {
      var data = scope.workPackage[scope.column.name];
      var defaultText = '';

      // Get display text from 'name' if it is an object
      var displayText = defaultText;
      switch(typeof(data)) {
        case 'string':
          displayText = data;
          break;
        case 'object':
          displayText = data['name'];
          break;
      }

      // Set type specific scope
      scope.displayText = displayText;

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
