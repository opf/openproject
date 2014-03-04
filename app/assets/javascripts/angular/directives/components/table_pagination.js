angular.module('openproject.uiComponents')

.directive('tablePagination', [function(){
  return {
    restrict: 'EA',
    templateUrl: '/templates/components/table_pagination.html',
    scope: {
      paginationOptions: '=',
      perPageOptions: '=',
      totalEntries: '=',
      updateResults: '&'
    },
    link: function(scope, element, attributes){
      scope.selectPerPage = function(perPage){
        scope.paginationOptions.perPage = perPage;

        updatePageNumbers();
        scope.showPage(1);
      };

      scope.showPage = function(pageNumber){
        scope.paginationOptions.page = pageNumber;

        updateCurrentRange();
        scope.updateResults(); // update table
      };

      /**
       * @name updateCurrentRange
       *
       * @description Defines a string containing page bound information inside the directive scope
       */
      updateCurrentRange = function() {
        var page = scope.paginationOptions.page;
        var perPage = scope.paginationOptions.perPage;

        scope.currentRange = "(" + getLowerPageBound(page, perPage) + " - " + getUpperPageBound(page, perPage) + "/" + scope.totalEntries + ")";
      };

      function getLowerPageBound(page, perPage) {
        return perPage * (page - 1) + 1;
      }

      function getUpperPageBound(page, perPage) {
        return Math.min(perPage * page, scope.totalEntries);
      }

      /**
       * @name updatePageNumbers
       *
       * @description Defines a list of all pages in numerical order inside the scope
       */
      updatePageNumbers = function() {
        var pageNumbers = [];
        for (var i = 1; i <= Math.ceil(scope.totalEntries / scope.paginationOptions.perPage); i++) {
          pageNumbers.push(i);
        }
        scope.pageNumbers = pageNumbers;
      };

      scope.$watch('totalEntries', function() {
        updateCurrentRange();
        updatePageNumbers();
      });

    }
  };
}]);
