angular.module('openproject.uiComponents')

.directive('tablePagination', ['PaginationService', function(PaginationService) {
  return {
    restrict: 'EA',
    templateUrl: '/templates/components/table_pagination.html',
    scope: {
      totalEntries: '=',
      updateResults: '&'
    },
    link: function(scope, element, attributes) {
      scope.paginationOptions = PaginationService.getPaginationOptions();

      scope.selectPerPage = function(perPage){
        PaginationService.setPerPage(perPage);

        updatePageNumbers();
        scope.showPage(1);
      };

      scope.showPage = function(pageNumber){
        PaginationService.setPage(pageNumber);

        updateCurrentRangeLabel();
        updatePageNumbers();

        scope.updateResults(); // update table
      };

      /**
       * @name updateCurrentRange
       *
       * @description Defines a string containing page bound information inside the directive scope
       */
      function updateCurrentRangeLabel() {
        scope.currentRange = "(" + PaginationService.getLowerPageBound() + " - " + PaginationService.getUpperPageBound(scope.totalEntries) + "/" + scope.totalEntries + ")";
      }

      /**
       * @name updatePageNumbers
       *
       * @description Defines a list of all pages in numerical order inside the scope
       */
      function updatePageNumbers() {
        var maxVisible = PaginationService.getMaxVisiblePageOptions();
        var truncSize = PaginationService.getOptionsTruncationSize();

        var pageNumbers = [];
        for (var i = 1; i <= Math.ceil(scope.totalEntries / scope.paginationOptions.perPage); i++) {
          pageNumbers.push(i);
        }

        if (PaginationService.getPage() >= maxVisible){
          var prePageNumbers = pageNumbers.splice(0, Math.min(PaginationService.getPage() - Math.ceil(maxVisible / 2), pageNumbers.length - maxVisible));
          if (prePageNumbers.length >= truncSize * 2) prePageNumbers.splice(truncSize, prePageNumbers.length - truncSize)
          scope.prePageNumbers = prePageNumbers;
        } else {
          scope.prePageNumbers = [];
        }

        if (pageNumbers.length >= maxVisible + (truncSize * 2)){
          var postPageNumbers = pageNumbers.splice(maxVisible, pageNumbers.length);
          if (postPageNumbers.length >= truncSize * 2) postPageNumbers.splice(0, postPageNumbers.length - truncSize)
          scope.postPageNumbers = postPageNumbers;
        } else {
          scope.postPageNumbers = [];
        }

        scope.pageNumbers = pageNumbers;
      }

      scope.$watch('totalEntries', function() {
        updateCurrentRangeLabel();
        updatePageNumbers();
      });

    }
  };
}]);
