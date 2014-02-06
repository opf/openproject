openprojectApp.directive('workPackagesTable', ['I18n', function(I18n){
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/templates/work_packages/work_packages_table.html',
    scope: {columns: '=', rows: '=', currentSortation: '=', projectIdentifier: '='},
    link: function(scope, element, attributes) {
      scope.I18n = I18n;
    }
  };
}]);
