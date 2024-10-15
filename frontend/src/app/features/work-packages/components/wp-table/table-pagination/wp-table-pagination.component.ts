//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnDestroy,
  OnInit,
} from '@angular/core';
import { combineLatest } from 'rxjs';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  WorkPackageViewPaginationService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-pagination.service';
import {
  WorkPackageViewPagination,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-table-pagination';
import {
  WorkPackageViewSortByService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { TablePaginationComponent } from 'core-app/shared/components/table-pagination/table-pagination.component';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';

@Component({
  templateUrl: '../../../../../shared/components/table-pagination/table-pagination.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'wp-table-pagination',
})
export class WorkPackageTablePaginationComponent extends TablePaginationComponent implements OnInit, OnDestroy {
  constructor(
    protected paginationService:PaginationService,
    protected cdRef:ChangeDetectorRef,
    protected wpTablePagination:WorkPackageViewPaginationService,
    readonly querySpace:IsolatedQuerySpace,
    readonly wpTableSortBy:WorkPackageViewSortByService,
    readonly I18n:I18nService,
  ) {
    super(paginationService, cdRef, I18n, wpTableSortBy);
  }

  ngOnInit() {
    super.ngOnInit();

    this.wpTablePagination
      .live$()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((wpPagination:WorkPackageViewPagination) => {
        this.pagination = wpPagination.current;
        this.update();
      });

    // hide/show pagination options depending on the sort mode
    combineLatest([
      this.querySpace.query.values$(),
      this.wpTableSortBy.live$(),
    ]).pipe(
      this.untilDestroyed(),
    ).subscribe(([query, sort]) => {
      this.showPerPage = this.showPageSelections = !this.isManualSortingMode;
      this.infoText = this.paginationInfoText(query.results);

      this.update();
    });
  }

  public selectPerPage(perPage:number) {
    this.paginationService.setPerPage(perPage);
    this.wpTablePagination.updateFromObject({ page: 1, perPage });
  }

  public showPage(pageNumber:number) {
    this.wpTablePagination.updateFromObject({ page: pageNumber });
  }

  private get isManualSortingMode() {
    return this.wpTableSortBy.isManualSortingMode;
  }

  public paginationInfoText(work_packages:WorkPackageCollectionResource) {
    if (this.isManualSortingMode && (work_packages.count < work_packages.total)) {
      return I18n.t('js.work_packages.endless_scroll');
    }
    return undefined;
  }
}
