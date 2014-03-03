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
        updatePageNumbers();
        scope.showPage(1);
      };

      scope.showPage = function(pageNumber){
        scope.page = pageNumber;
        updateCurrentRange();
      };

      updateCurrentRange = function() {
        scope.currentRange = "(" + getLowerPageBound(scope.page, scope.perPage) + " - " + getUpperPageBound(scope.page, scope.perPage) + "/" + scope.totalEntries + ")";
      };

      function getLowerPageBound(page, perPage) {
        return perPage * (page - 1) + 1;
      }

      function getUpperPageBound(page, perPage) {
        return Math.min(perPage * page, scope.totalEntries);
      }

      updatePageNumbers = function() {
        var pageNumbers = [];
        for (var i = 1; i <= Math.ceil(scope.totalEntries / scope.perPage); i++) {
          pageNumbers.push(i);
        }
        scope.pageNumbers = pageNumbers;
      };

      // initially calculate current range and page numbers
      updateCurrentRange();
      updatePageNumbers();
    }
  };
}]);
