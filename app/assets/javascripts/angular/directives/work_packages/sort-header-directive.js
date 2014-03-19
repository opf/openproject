angular.module('openproject.workPackages.directives')

.directive('sortHeader', ['I18n', 'PathHelper', function(I18n, PathHelper){

  return {
    restrict: 'A',
    templateUrl: '/templates/work_packages/sort_header.html',
    scope: {
      query: '=',
      headerName: '=',
      headerTitle: '=',
      sortable: '=',
      updateResults: '&'
    },
    link: function(scope, element, attributes) {
      scope.$watch('query.sortation', function(oldValue, newValue) {
        if (newValue !== oldValue) {
          scope.updateResults();
        }
      });

      scope.performSort = function(){
        targetSortation = scope.query.sortation.getTargetSortationOfHeader(scope.headerName);
        scope.query.setSortation(targetSortation);
        scope.currentSortDirection = scope.query.sortation.getDisplayedSortDirectionOfHeader(scope.headerName);
        scope.setFullTitle();
      };

      scope.setFullTitle = function(){
        if(!scope.sortable) scope.fullTitle = '';
        if(scope.currentSortDirection){
          var sortDirectionText = (scope.currentSortDirection == 'asc') ? I18n.t('js.label_ascending') : I18n.t('js.label_descending');
          scope.fullTitle = sortDirectionText + " " + I18n.t('js.label_sorted_by') + ' \"' + scope.headerTitle + '\"';
        } else {
          scope.fullTitle = (I18n.t('js.label_sort_by') + ' \"' + scope.headerTitle + '\"');
        }
      };

      scope.currentSortDirection = scope.query.sortation.getDisplayedSortDirectionOfHeader(scope.headerName);
      scope.setFullTitle();
    }
  };
}]);
