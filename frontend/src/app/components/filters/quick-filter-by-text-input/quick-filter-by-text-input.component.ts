//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { Component, EventEmitter, Output } from '@angular/core';
import { I18nService } from "app/modules/common/i18n/i18n.service";
import { WorkPackageViewFiltersService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import { Subject } from "rxjs";
import { debounceTime, distinctUntilChanged, map, tap } from "rxjs/operators";
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { input } from "reactivestates";
import { QueryFilterResource } from "core-app/modules/hal/resources/query-filter-resource";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

@Component({
  selector: 'wp-filter-by-text-input',
  templateUrl: './quick-filter-by-text-input.html'
})

export class WorkPackageFilterByTextInputComponent extends UntilDestroyedMixin {
  @Output() public deactivateFilter = new EventEmitter<QueryFilterResource>();

  public text = {
    createWithDropdown: this.I18n.t('js.work_packages.create.button'),
    createButton: this.I18n.t('js.label_work_package'),
    explanation: this.I18n.t('js.label_create_work_package'),
    placeholder: this.I18n.t('js.work_packages.placeholder_filter_by_text')
  };

  /** Observable to the current search filter term */
  public searchTerm = input<string>('');

  /** Input for search requests */
  public searchTermChanged:Subject<string> = new Subject<string>();

  constructor(readonly I18n:I18nService,
              readonly querySpace:IsolatedQuerySpace,
              readonly wpTableFilters:WorkPackageViewFiltersService) {
    super();

    this.wpTableFilters
      .pristine$()
      .pipe(
        this.untilDestroyed(),
        map(() => {
          const currentSearchFilter = this.wpTableFilters.find('search');
          return currentSearchFilter ? (currentSearchFilter.values[0] as string) : '';
        }),
      )
      .subscribe((upstreamTerm:string) => {
        console.log("upstream " + upstreamTerm + " " + (this.searchTerm as any).timestampOfLastValue);
        if (!this.searchTerm.value || this.searchTerm.isValueOlderThan(500)) {
          console.log("Upstream value setting to " + upstreamTerm);
          this.searchTerm.putValue(upstreamTerm);
        }
      });

    this.searchTermChanged
      .pipe(
        this.untilDestroyed(),
        distinctUntilChanged(),
        tap((val) => this.searchTerm.putValue(val)),
        debounceTime(500),
      )
      .subscribe(term => {
        if (term.length > 0) {
          this.wpTableFilters.replace('search', filter => {
            filter.operator = filter.findOperator('**')!;
            filter.values = [term];
          });
        } else {
          const filter = this.wpTableFilters.find('search');

          this.wpTableFilters.remove(filter!);

          this.deactivateFilter.emit(filter);
        }
      });
  }
}
