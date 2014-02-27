angular.module('openproject.uiComponents')

.directive('tablePagination', [function(){
  return {
    restrict: 'EA',
    templateUrl: '/templates/components/table_pagination.html',
    scope: {
      page: '=',
      perPage: '=',
      rows: '='
    },
    link: function(scope, element, attributes){
      scope.selectPerPage = function(perPage){
        scope.perPage = perPage;
      };

      scope.possiblePerPages = [100, 500, 1000]; // TODO: These should come from somewhere sensible
      scope.currentRange = "(" + ((scope.perPage * (scope.page - 1)) + 1) + " - " + scope.rows.length + "/" + scope.rows.length + ")"
    }
  }
}])
