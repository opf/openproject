// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {TablePaginationComponent} from 'core-components/table-pagination/table-pagination.component';
import {ChangeDetectionStrategy, ChangeDetectorRef, Component, OnDestroy, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {IPaginationOptions, PaginationService} from 'core-components/table-pagination/pagination-service';
import {WorkPackageViewPaginationService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-pagination.service";
import {WorkPackageViewPagination} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-table-pagination";
import {WorkPackageViewSortByService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-sort-by.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {combineLatest} from 'rxjs';
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";

@Component({
  templateUrl: '../../table-pagination/table-pagination.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'wp-table-pagination'
})
export class WorkPackageTablePaginationComponent extends TablePaginationComponent implements OnInit, OnDestroy {

  constructor(protected paginationService:PaginationService,
              protected cdRef:ChangeDetectorRef,
              protected wpTablePagination:WorkPackageViewPaginationService,
              readonly querySpace:IsolatedQuerySpace,
              readonly wpTableSortBy:WorkPackageViewSortByService,
              readonly I18n:I18nService) {
    super(paginationService, cdRef, I18n);

  }

  ngOnInit() {
    this.paginationService
      .loadPaginationOptions()
      .then((paginationOptions:IPaginationOptions) => {
        this.perPageOptions = paginationOptions.perPageOptions;
        this.cdRef.detectChanges();
      });

    this.wpTablePagination
      .live$()
      .pipe(
        this.untilDestroyed()
      )
      .subscribe((wpPagination:WorkPackageViewPagination) => {
        this.pagination = wpPagination.current;
        this.update();
      });

    // hide/show pagination options depending on the sort mode
    combineLatest([
      this.querySpace.query.values$(),
      this.wpTableSortBy.live$()
    ]).pipe(
      this.untilDestroyed()
    ).subscribe(([query, sort]) => {
      this.showPerPage = this.showPageSelections = !this.isManualSortingMode;
      this.infoText = this.paginationInfoText(query.results);

      this.update();
    });
  }

  public selectPerPage(perPage:number) {
    this.paginationService.setPerPage(perPage);
    this.wpTablePagination.updateFromObject({ page: 1, perPage: perPage });
  }

  public showPage(pageNumber:number) {
    this.wpTablePagination.updateFromObject({ page: pageNumber });
  }

  private get isManualSortingMode() {
    return this.wpTableSortBy.isManualSortingMode;
  }

  public paginationInfoText(work_packages:WorkPackageCollectionResource) {
    if (this.isManualSortingMode && (work_packages.count < work_packages.total)) {
      return I18n.t('js.work_packages.limited_results',
        { count: work_packages.count });
    } else {
      return undefined;
    }
  }
}
