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
      };

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

        scope.prePageNumbers = truncatePageNums(pageNumbers, PaginationService.getPage() >= maxVisible, 0, Math.min(PaginationService.getPage() - Math.ceil(maxVisible / 2), pageNumbers.length - maxVisible), truncSize);
        scope.postPageNumbers = truncatePageNums(pageNumbers, pageNumbers.length >= maxVisible + (truncSize * 2), maxVisible, pageNumbers.length, 0);
        scope.pageNumbers = pageNumbers;
      };

      function truncatePageNums(pageNumbers, perform, disectFrom, disectLength, truncateFrom){
        if (perform){
          var tuncationSize = PaginationService.getOptionsTruncationSize();
          var truncatedNums = pageNumbers.splice(disectFrom, disectLength);
          if (truncatedNums.length >= tuncationSize * 2) truncatedNums.splice(truncateFrom, truncatedNums.length - tuncationSize)
          return truncatedNums;
        } else {
          return [];
        }
      };

      scope.$watch('totalEntries', function() {
        updateCurrentRangeLabel();
        updatePageNumbers();
      });

    }
  };
}]);
