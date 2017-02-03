import {WorkPackageTableMetadata} from '../../wp-fast-table/wp-table-metadata';
// -- copyright
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
// ++

import {WorkPackageTableMetadataService} from '../../wp-fast-table/state/wp-table-metadata.service';

angular
  .module('openproject.workPackages.directives')
  .directive('tablePagination', tablePagination);

function tablePagination(PaginationService,
                         wpTableMetadata:WorkPackageTableMetadataService,
                         I18n:op.I18n) {
  return {
    restrict: 'EA',
    templateUrl: '/components/wp-table/table-pagination/table-pagination.directive.html',

    scope: {
      updateResults: '&'
    },

    link: function(scope) {
      scope.I18n = I18n;
      scope.paginationOptions = PaginationService.getPaginationOptions();
      scope.text = {
        label_previous: I18n.t('js.pagination.pages.previous'),
        label_next: I18n.t('js.pagination.pages.next'),
        per_page: I18n.t('js.label_per_page'),
        no_other_page: I18n.t('js.pagination.no_other_page')
      };

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

        // This avoids a truncation when there are not enough elements to truncate for the first elements
        var startingDiff = PaginationService.getPage() - 2 * truncSize;
        if ( 0 <= startingDiff && startingDiff <= 1 ) {
          scope.postPageNumbers = truncatePageNums(pageNumbers, pageNumbers.length >= maxVisible + (truncSize * 2), maxVisible + truncSize, pageNumbers.length, 0);
        }
        else {
          scope.prePageNumbers = truncatePageNums(pageNumbers, PaginationService.getPage() >= maxVisible, 0, Math.min(PaginationService.getPage() - Math.ceil(maxVisible / 2), pageNumbers.length - maxVisible), truncSize);
          scope.postPageNumbers = truncatePageNums(pageNumbers, pageNumbers.length >= maxVisible + (truncSize * 2), maxVisible, pageNumbers.length, 0);
        }

        scope.pageNumbers = pageNumbers;
      }

      function truncatePageNums(pageNumbers, perform, disectFrom, disectLength, truncateFrom){
        if (perform){
          var truncationSize = PaginationService.getOptionsTruncationSize();
          var truncatedNums = pageNumbers.splice(disectFrom, disectLength);
          if (truncatedNums.length >= truncationSize * 2) truncatedNums.splice(truncateFrom, truncatedNums.length - truncationSize);
          return truncatedNums;
        } else {
          return [];
        }
      }

      wpTableMetadata.metadata.observe(scope).subscribe((metadata:WorkPackageTableMetadata) => {
        scope.totalEntries = metadata.total;
        updateCurrentRangeLabel();
        updatePageNumbers();
      });
    }
  };
}
