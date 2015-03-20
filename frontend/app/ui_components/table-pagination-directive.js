//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

module.exports = function(I18n, PaginationService) {
  return {
    restrict: 'EA',
    templateUrl: '/templates/components/table_pagination.html',
    scope: {
      totalEntries: '=',
      updateResults: '&'
    },
    link: function(scope, element, attributes) {
      scope.I18n = I18n;
      scope.paginationOptions = PaginationService.getPaginationOptions();

      scope.selectPerPage = function(perPage){
        PaginationService.setPerPage(perPage);

        updatePageNumbers();
        scope.showPage(1);
        scope.$emit('queryStateChange');
        scope.updateResults();
      };

      scope.showPage = function(pageNumber){
        PaginationService.setPage(pageNumber);

        updateCurrentRangeLabel();
        updatePageNumbers();

        scope.$emit('workPackagesRefreshRequired');
        scope.$emit('queryStateChange');
        scope.updateResults();
      };

      /**
       * @name updateCurrentRange
       *
       * @description Defines a string containing page bound information inside the directive scope
       */
      function updateCurrentRangeLabel() {
        if (scope.totalEntries){
          scope.currentRange = "(" + PaginationService.getLowerPageBound() + " - " + PaginationService.getUpperPageBound(scope.totalEntries) + "/" + scope.totalEntries + ")";
        } else {
          scope.currentRange = "(0 - 0/0)";
        }
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

        scope.prePageNumbers = truncatePageNums(pageNumbers, PaginationService.getPage() >= maxVisible, 0, Math.min(PaginationService.getPage() - Math.ceil(maxVisible / 2), pageNumbers.length - maxVisible), truncSize);
        scope.postPageNumbers = truncatePageNums(pageNumbers, pageNumbers.length >= maxVisible + (truncSize * 2), maxVisible, pageNumbers.length, 0);
        scope.pageNumbers = pageNumbers;
      }

      function truncatePageNums(pageNumbers, perform, disectFrom, disectLength, truncateFrom){
        if (perform){
          var tuncationSize = PaginationService.getOptionsTruncationSize();
          var truncatedNums = pageNumbers.splice(disectFrom, disectLength);
          if (truncatedNums.length >= tuncationSize * 2) truncatedNums.splice(truncateFrom, truncatedNums.length - tuncationSize);
          return truncatedNums;
        } else {
          return [];
        }
      }

      scope.$watch('totalEntries', function() {
        updateCurrentRangeLabel();
        updatePageNumbers();
      });

    }
  };
};
