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

import {PaginationService} from 'core-components/table-pagination/pagination-service';
import {PaginationInstance} from 'core-components/table-pagination/pagination-instance';
import {IPaginationOptions} from './pagination-service';
import {Component, EventEmitter, Input, OnInit, Output} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';

@Component({
  selector: '[tablePagination]',
  templateUrl: './table-pagination.component.html'
})
export class TablePaginationComponent implements OnInit {
  @Input() totalEntries:string;
  @Input() hideForSinglePageResults:boolean = false;
  @Input() calculatePerPage:boolean = false;
  @Output() updateResults = new EventEmitter<PaginationInstance>();

  public pagination:PaginationInstance;
  public text = {
    label_previous: this.I18n.t('js.pagination.pages.previous'),
    label_next: this.I18n.t('js.pagination.pages.next'),
    per_page: this.I18n.t('js.label_per_page'),
    no_other_page: this.I18n.t('js.pagination.no_other_page')
  };

  public currentRange:string = '';
  public pageNumbers:number[] = [];
  public postPageNumbers:number[] = [];
  public prePageNumbers:number[] = [];
  public perPageOptions:number[] = [];

  constructor(protected paginationService:PaginationService,
              readonly I18n:I18nService) {
  }

  ngOnInit():void {
    this.paginationService
      .loadPaginationOptions()
      .then((paginationOptions:IPaginationOptions) => {
        this.perPageOptions = paginationOptions.perPageOptions;
        this.newPagination(paginationOptions);
      });
  }

  public newPagination(paginationOptions:IPaginationOptions) {
    this.pagination = new PaginationInstance(1, parseInt(this.totalEntries), paginationOptions.perPage);
  }

  public update() {
    this.updateCurrentRangeLabel();
    this.updatePageNumbers();
  }

  public selectPerPage(perPage:number) {
    this.pagination.perPage = perPage;
    this.paginationService.setPerPage(perPage);
    this.showPage(1);
  }

  public showPage(page:number) {
    this.pagination.page = page;

    this.updateCurrentRangeLabel();
    this.updatePageNumbers();

    this.onUpdatedPage();
  }

  public onUpdatedPage() {
    this.updateResults.emit(this.pagination);
  }

  public get isVisible() {
    return !this.hideForSinglePageResults || (this.pagination.total > this.pagination.perPage);
  }

  /**
   * @name updateCurrentRange
   *
   * @description Defines a string containing page bound information inside the directive scope
   */
  public updateCurrentRangeLabel() {
    if (this.pagination.total) {
      this.currentRange = '(' + this.pagination.getLowerPageBound() + ' - ' + this.pagination.getUpperPageBound(this.pagination.total) + '/' + this.pagination.total + ')';
    } else {
      this.currentRange = '(0 - 0/0)';
    }
  }

  /**
   * @name updatePageNumbers
   *
   * @description Defines a list of all pages in numerical order inside the scope
   */
  public updatePageNumbers() {
    var maxVisible = this.paginationService.getMaxVisiblePageOptions();
    var truncSize = this.paginationService.getOptionsTruncationSize();

    var pageNumbers = [];

    const perPage = this.pagination.perPage;
    const currentPage = this.pagination.page;
    if (perPage) {
      for (var i = 1; i <= Math.ceil(this.pagination.total / perPage); i++) {
        pageNumbers.push(i);
      }

      // This avoids a truncation when there are not enough elements to truncate for the first elements
      var startingDiff = currentPage - 2 * truncSize;
      if ( 0 <= startingDiff && startingDiff <= 1 ) {
        this.postPageNumbers = this.truncatePageNums(pageNumbers, pageNumbers.length >= maxVisible + (truncSize * 2), maxVisible + truncSize, pageNumbers.length, 0);
      }
      else {
        this.prePageNumbers = this.truncatePageNums(pageNumbers, currentPage >= maxVisible, 0, Math.min(currentPage - Math.ceil(maxVisible / 2), pageNumbers.length - maxVisible), truncSize);
        this.postPageNumbers = this.truncatePageNums(pageNumbers, pageNumbers.length >= maxVisible + (truncSize * 2), maxVisible, pageNumbers.length, 0);
      }
    }

    this.pageNumbers = pageNumbers;
  }

  public showPerPageOptions() {
    return !this.calculatePerPage &&
           this.perPageOptions.length > 0 &&
           this.pagination.total > this.perPageOptions[0]
  }

  private truncatePageNums(pageNumbers:any, perform:any, disectFrom:any, disectLength:any, truncateFrom:any) {
    if (perform) {
      var truncationSize = this.paginationService.getOptionsTruncationSize();
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
