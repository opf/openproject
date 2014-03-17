// TODO move to UI components
angular.module('openproject.workPackages.directives')

.directive('workPackageColumn', ['PathHelper', 'WorkPackagesHelper', function(PathHelper, WorkPackagesHelper){
  return {
    restrict: 'EA',
    replace: true,
    scope: {
      workPackage: '=',
      column: '=',
      displayType: '='
    },
    templateUrl: '/templates/components/work_package_column.html',
    link: function(scope, element, attributes) {
      var defaultText = '';
      var defaultType = 'text';

      scope.displayType = scope.displayType || defaultType;
      if (scope.column.name === 'done_ratio') scope.displayType = 'progress_bar';

      // Set text to be displayed
      scope.$watch('workPackage', updateColumnData, true);

      function updateColumnData() {
        scope.displayText = WorkPackagesHelper.getFormattedColumnValue(scope.workPackage, scope.column) || defaultText;

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
