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

import {Component, Input, OnDestroy, Output} from '@angular/core';
import {WorkPackageTableFiltersService} from 'core-components/wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableFilters} from 'core-components/wp-fast-table/wp-table-filters';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {WorkPackageFiltersService} from 'core-components/filters/wp-filters/wp-filters.service';
import {DebouncedEventEmitter} from "core-components/angular/debounced-event-emitter";

@Component({
  templateUrl: './filter-container.directive.html',
  selector: 'filter-container',
})
export class WorkPackageFilterContainerComponent implements OnDestroy {
  @Input('showFilterButton') showFilterButton:boolean = false;
  @Input('filterButtonText') filterButtonText:string = I18n.t('js.button_filter');
  @Output() public filtersChanged = new DebouncedEventEmitter<WorkPackageTableFilters>(componentDestroyed(this));

  public filters = this.wpTableFilters.currentState;

  constructor(readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly wpFiltersService:WorkPackageFiltersService) {
    this.wpTableFilters
      .observeUntil(componentDestroyed(this))
      .subscribe(() => {
        this.filters = this.wpTableFilters.currentState;
    });
  }

  ngOnDestroy() {
    // Nothing to do, added for interface compatibility
  }

  public replaceIfComplete(filters:WorkPackageTableFilters) {
    this.wpTableFilters.replaceIfComplete(filters);
    this.filtersChanged.emit(this.filters);
  }
}
