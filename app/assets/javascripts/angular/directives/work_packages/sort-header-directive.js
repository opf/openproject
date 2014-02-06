openprojectApp.directive('sortHeader', ['I18n', 'PathHelper', function(I18n, PathHelper){

  getQueryString = function(headerName, sortOrder) {
    return 'set_filter=1&amp;sort=' + headerName + '%2Cparent%3A' + sortOrder;
  };

  getSortState = function(headerName, params) {
    return null; // TODO implement
  };

  return {
    // TODO isolate and restrict to 'E' once https://github.com/angular/angular.js/issues/1459 is solved
    restrict: 'A',
    templateUrl: '/templates/work_packages/sort_header.html',
    scope: true,
    link: function(scope, element, attributes) {
      sortOrder = 'asc';
      headerName = attributes['headerName'];

      scope.headerTitle = attributes['headerTitle'];
      scope.sortable = attributes['sortable'];

      scope.I18n = I18n;
      scope.path = PathHelper.projectWorkPackagesPath(scope.projectIdentifier);
      scope.queryString = getQueryString(headerName, sortOrder);

      scope.sortState = getSortState(headerName, {});
    }
  };
}]);
