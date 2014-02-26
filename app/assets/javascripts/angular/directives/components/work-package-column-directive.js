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
      scope.$watch('workPackage', updateColumnData, true);

      function updateColumnData() {
        scope.displayText = WorkPackagesHelper.getColumnValue(scope.workPackage, scope.column) || defaultText;
        scope.displayType = defaultType;

        // Example of how we can look to the provided meta data to format the column
        // This relies on the meta being sent from the server
        if (scope.column.meta_data.link.display) {
          scope.displayType = 'link';
          scope.url = getLinkFor(scope.column.meta_data.link);
        }

      }

      function getLinkFor(link_meta){
        switch (link_meta.model_type){
          case 'work_package':
            url = PathHelper.workPackagePath(scope.workPackage.id);
            break;
          case 'user':
            if (scope.workPackage[scope.column.name]) url = PathHelper.userPath(scope.workPackage[scope.column.name].id);
            break;
          case 'project':
            if (scope.workPackage.project) url = PathHelper.projectPath(scope.workPackage.project.identifier);
            break;
          default:
            url = "";
        };
        return url;
      }

    }
  };
}]);
