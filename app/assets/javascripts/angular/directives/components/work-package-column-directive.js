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
      var defaultType = 'text';

      // Set text to be displayed
      scope.displayText = WorkPackagesHelper.getRowObjectContent(scope.workPackage, scope.column.name) || defaultText;
      scope.displayType = defaultType;


      // TODO RS: Manually set all the column display types. We will need:
      //          Text, Link... what else?
      //          Date formatting is much easier server side. Check time_with_zone_as_json initializer.

      switch (scope.column.name){
        case 'subject':
          scope.displayType = 'link';
          scope.url = PathHelper.workPackagePath(scope.workPackage.id);
          break;
        case 'assigned_to':
          scope.displayType = 'link';
          if (scope.workPackage.assigned_to) scope.url = PathHelper.userPath(scope.workPackage.assigned_to.id);
          break;
        case 'responsible':
          scope.displayType = 'link';
          if (scope.workPackage.responsible) scope.url = PathHelper.userPath(scope.workPackage.responsible.id);
          break;
        case 'author':
          scope.displayType = 'link';
          if (scope.workPackage.author) scope.url = PathHelper.userPath(scope.workPackage.author.id);
          break;
        case 'project':
          scope.displayType = 'link';
          if (scope.workPackage.project) scope.url = PathHelper.projectPath(scope.workPackage.project.identifier);
          break;

      }

    }
  };
}]);
