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

import {ConfigurationResource} from '../api/api-v3/hal-resources/configuration-resource.service';
import {ConfigurationDmService} from '../api/api-v3/hal-resource-dms/configuration-dm.service';
import {WorkPackageTablePaginationService} from '../wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTablePagination} from '../wp-fast-table/wp-table-pagination';
export class TablePaginationController {
  constructor(protected $scope:ng.IScope,
              protected PaginationService:any,
              protected I18n:op.I18n) {
    $scope.text = {
      label_previous: I18n.t('js.pagination.pages.previous'),
      label_next: I18n.t('js.pagination.pages.next'),
      per_page: I18n.t('js.label_per_page'),
      no_other_page: I18n.t('js.pagination.no_other_page')
    };

    PaginationService.loadPerPageOptions();

    $scope.paginationOptions = PaginationService.getPaginationOptions();

    Object.defineProperty($scope, 'perPageOptions', {
      get: () => this.PaginationService.getPerPageOptions()
    });
  }

  /**
   * @name updateCurrentRange
   *
   * @description Defines a string containing page bound information inside the directive scope
   */
  public updateCurrentRangeLabel() {
    if (this.$scope.totalEntries) {
      this.$scope.currentRange = '(' + this.PaginationService.getLowerPageBound() + ' - ' + this.PaginationService.getUpperPageBound(this.$scope.totalEntries) + '/' + this.$scope.totalEntries + ')';
    } else {
      this.$scope.currentRange = '(0 - 0/0)';
    }
  }

  /**
   * @name updatePageNumbers
   *
   * @description Defines a list of all pages in numerical order inside the scope
   */
  public updatePageNumbers() {
    var maxVisible = this.PaginationService.getMaxVisiblePageOptions();
    var truncSize = this.PaginationService.getOptionsTruncationSize();

    var pageNumbers = [];

    if (this.$scope.paginationOptions.perPage) {
      for (var i = 1; i <= Math.ceil(this.$scope.totalEntries / this.$scope.paginationOptions.perPage); i++) {
        pageNumbers.push(i);
      }
    }

    // This avoids a truncation when there are not enough elements to truncate for the first elements
    var startingDiff = this.PaginationService.getPage() - 2 * truncSize;
    if ( 0 <= startingDiff && startingDiff <= 1 ) {
      this.$scope.postPageNumbers = this.truncatePageNums(pageNumbers, pageNumbers.length >= maxVisible + (truncSize * 2), maxVisible + truncSize, pageNumbers.length, 0);
    }
    else {
      this.$scope.prePageNumbers = this.truncatePageNums(pageNumbers, this.PaginationService.getPage() >= maxVisible, 0, Math.min(this.PaginationService.getPage() - Math.ceil(maxVisible / 2), pageNumbers.length - maxVisible), truncSize);
      this.$scope.postPageNumbers = this.truncatePageNums(pageNumbers, pageNumbers.length >= maxVisible + (truncSize * 2), maxVisible, pageNumbers.length, 0);
    }

    this.$scope.pageNumbers = pageNumbers;
  }

  private truncatePageNums(pageNumbers:any, perform:any, disectFrom:any, disectLength:any, truncateFrom:any) {
    if (perform) {
      var truncationSize = this.PaginationService.getOptionsTruncationSize();
      var truncatedNums = pageNumbers.splice(disectFrom, disectLength);
      if (truncatedNums.length >= truncationSize * 2) {
        truncatedNums.splice(truncateFrom, truncatedNums.length - truncationSize);
      }
      return truncatedNums;
    } else {
      return [];
    }
  }
}
