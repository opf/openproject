openprojectApp.directive('sortHeader', ['I18n', 'PathHelper', function(I18n, PathHelper){

  var defaultSortDirection = 'asc';

  var getQueryString = function(headerName, sortOrder) {
    return 'set_filter=1&sort=' + headerName + '%2Cparent%3A' + sortOrder;
  };

  return {
    // TODO isolate and restrict to 'E' once https://github.com/angular/angular.js/issues/1459 is solved
    restrict: 'A',
    templateUrl: '/templates/work_packages/sort_header.html',
    scope: true,
    link: function(scope, element, attributes) {
      getAllSortations = function() {
        if (!scope.currentSortation) return [];

        return scope.currentSortation.split(',').map(function(sortParam) {
          fieldAndDirection = sortParam.split(':');
          return { field: fieldAndDirection[0], direction: fieldAndDirection[1] || defaultSortDirection};
        });
      };

      getCurrentSortation = function() {
        return getAllSortations().first();
      };

      getSortDirectionOfHeader = function(headerName) {
        var sortDirection;
        var currentSortation = getCurrentSortation();

        if(currentSortation && currentSortation.field === headerName) sortDirection = currentSortation.direction;

        return sortDirection;
      };

      sortOrder = 'asc';
      headerName = attributes['headerName'];

      scope.headerTitle = attributes['headerTitle'];
      scope.sortable = attributes['sortable'];

      scope.I18n = I18n;
      scope.path = PathHelper.projectWorkPackagesPath(scope.projectIdentifier);
      scope.queryString = getQueryString(headerName, sortOrder);

      scope.currentSortDirection = getSortDirectionOfHeader(headerName);
    }
  };
}]);
