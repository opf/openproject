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

import {ConfigurationResource} from '../../api/api-v3/hal-resources/configuration-resource.service';
import {ConfigurationDmService} from '../../api/api-v3/hal-resource-dms/configuration-dm.service';
import {WorkPackageTablePaginationService} from '../../wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTablePagination} from '../../wp-fast-table/wp-table-pagination';
import {wpDirectivesModule} from '../../../angular-modules';
import {TablePaginationComponent} from 'core-components/table-pagination/table-pagination.component';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {Inject, OnDestroy, Component} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {PaginationService} from 'core-components/table-pagination/pagination-service';
import {downgradeComponent} from '@angular/upgrade/static';

@Component({
  template: require('!!raw-loader!core-components/table-pagination/table-pagination.component.html'),
  selector: 'wp-table-pagination'
})
export class WorkPackageTablePaginationComponent extends TablePaginationComponent implements OnDestroy {
  constructor(protected paginationService:PaginationService,
              protected wpTablePagination:WorkPackageTablePaginationService,
              @Inject(I18nToken) protected I18n:op.I18n) {
    super(paginationService, I18n);

  }

  public newPagination() {
    this.wpTablePagination
      .observeUntil(componentDestroyed(this))
      .subscribe((wpPagination:WorkPackageTablePagination) => {
        this.pagination = wpPagination.current;
        this.update();
    });
  }

  ngOnDestroy():void {
    // Empty
  }

  public selectPerPage(perPage:number) {
    this.wpTablePagination.updateFromObject({page: 1, perPage: perPage});
 }

  public showPage(pageNumber:number) {
    this.wpTablePagination.updateFromObject({page: pageNumber});
  }
}

wpDirectivesModule
  .directive('wpTablePagination',
             downgradeComponent({component: WorkPackageTablePaginationComponent}));
