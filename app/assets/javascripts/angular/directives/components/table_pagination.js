angular.module('openproject.uiComponents')

.directive('tablePagination', [function(){
  return {
    restrict: 'EA',
    templateUrl: '/templates/components/table_pagination.html',
    scope: {
      page: '=',
      perPage: '=',
      perPageOptions: '=',
      totalEntries: '=',
      rows: '='
    },
    link: function(scope, element, attributes){
      scope.selectPerPage = function(perPage){
        scope.perPage = perPage;
        scope.page = 1;
        scope.currentRange = currentRange();
        scope.pageNumbers = pageNumbers();
      };

      scope.showPage = function(pageNumber){
        scope.page = pageNumber;
        scope.currentRange = currentRange();
        scope.pageNumbers = pageNumbers();
      };

      currentRange = function(){
        return "(" + ((scope.perPage * (scope.page - 1)) + 1) + " - " + scope.rows.length + "/" + scope.totalEntries + ")";
      };

      pageNumbers = function(){
        var pageNumbers = [];
        for (var i = 1; i <= Math.ceil(scope.totalEntries / scope.perPage); i++){
          pageNumbers.push(i);
        }
        return pageNumbers;
      }

      scope.currentRange = currentRange();
      scope.pageNumbers = pageNumbers();
    }
  }
}])
