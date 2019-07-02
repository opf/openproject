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

import {ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnDestroy, OnInit, Output} from '@angular/core';
import {WorkPackageTableFiltersService} from 'core-components/wp-fast-table/state/wp-table-filters.service';
import {componentDestroyed, untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {WorkPackageFiltersService} from 'core-components/filters/wp-filters/wp-filters.service';
import {DebouncedEventEmitter} from "core-components/angular/debounced-event-emitter";
import {QueryFilterInstanceResource} from "core-app/modules/hal/resources/query-filter-instance-resource";
import {Observable} from "rxjs";
import {takeUntil} from "rxjs/operators";

@Component({
  templateUrl: './filter-container.directive.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'filter-container',
})
export class WorkPackageFilterContainerComponent implements OnInit, OnDestroy {
  @Input('showFilterButton') showFilterButton:boolean = false;
  @Input('filterButtonText') filterButtonText:string = I18n.t('js.button_filter');
  @Output() public filtersChanged = new DebouncedEventEmitter<QueryFilterInstanceResource[]>(componentDestroyed(this));
  @Output() public filtersCompleted = new DebouncedEventEmitter<boolean>(componentDestroyed(this));

  public visible$:Observable<Boolean>;
  public filters = this.wpTableFilters.current;
  public loaded = false;

  constructor(readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly cdRef:ChangeDetectorRef,
              readonly wpFiltersService:WorkPackageFiltersService) {
    this.visible$ = this.wpFiltersService.observeUntil(componentDestroyed(this));
  }

  ngOnInit():void {
    this.wpTableFilters
      .pristine$()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe(() => {
        this.filters = this.wpTableFilters.current;
        this.loaded = true;
        this.cdRef.detectChanges();
      });
  }

  ngOnDestroy() {
    // Nothing to do, added for interface compatibility
  }

  public replaceIfComplete(filters:QueryFilterInstanceResource[]) {
    let complete = this.wpTableFilters.replaceIfComplete(filters);
    this.filtersCompleted.emit(complete);
    this.filtersChanged.emit(this.filters);
  }
}
