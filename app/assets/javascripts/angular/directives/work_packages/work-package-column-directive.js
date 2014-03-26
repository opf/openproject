// TODO move to UI components
angular.module('openproject.workPackages.directives')

.directive('workPackageColumn', ['PathHelper', 'WorkPackagesHelper', 'UserService', function(PathHelper, WorkPackagesHelper, UserService){
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      workPackage: '=',
      column: '=',
      displayType: '@'
    },
    templateUrl: '/templates/work_packages/work_package_column.html',
    link: function(scope, element, attributes) {
      scope.displayType = scope.displayType || 'text';

      // custom display types
      if (scope.column.name === 'done_ratio') {
        scope.displayType = 'progress_bar';
      }

      // Set text to be displayed
      scope.$watch('workPackage', setColumnData, true);

      function setColumnData() {
        // retrieve column value from work package
        scope.displayText = WorkPackagesHelper.getFormattedColumnValue(scope.workPackage, scope.column) || '';

        // Example of how we can look to the provided meta data to format the column
        // This relies on the meta being sent from the server
        if (scope.column.meta_data.link.display) {
          scope.displayType = 'link';
          scope.url = getLinkFor(scope.column.meta_data.link);
        }
      }

      function getLinkFor(link_meta){
        if (link_meta.model_type === 'work_package') {
          return PathHelper.workPackagePath(scope.workPackage.id);
        } else if (scope.workPackage[scope.column.name]) {
          switch (link_meta.model_type) {
            case 'user':
              return PathHelper.userPath(scope.workPackage[scope.column.name].id);
            case 'version':
              return PathHelper.versionPath(scope.workPackage[scope.column.name].id);
            case 'project':
              return PathHelper.projectPath(scope.workPackage.project.identifier);
            default:
              return '';
          }

        }
      }

    }
  };
}]);
