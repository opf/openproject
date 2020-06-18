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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Input,
  OnDestroy,
  OnInit,
  Output,
  ViewEncapsulation
} from '@angular/core';
import {WorkPackageViewFiltersService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service';
import {WorkPackageFiltersService} from 'core-components/filters/wp-filters/wp-filters.service';
import {DebouncedEventEmitter} from "core-components/angular/debounced-event-emitter";
import {QueryFilterInstanceResource} from "core-app/modules/hal/resources/query-filter-instance-resource";
import {Observable} from "rxjs";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {componentDestroyed} from "@w11k/ngx-componentdestroyed";

@Component({
  templateUrl: './filter-container.directive.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'filter-container'
})
export class WorkPackageFilterContainerComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @Input('showFilterButton') showFilterButton:boolean = false;
  @Input('filterButtonText') filterButtonText:string = I18n.t('js.button_filter');
  @Output() public filtersChanged = new DebouncedEventEmitter<QueryFilterInstanceResource[]>(componentDestroyed(this));

  public visible$:Observable<Boolean>;
  public filters = this.wpTableFilters.current;
  public loaded = false;

  constructor(readonly wpTableFilters:WorkPackageViewFiltersService,
              readonly cdRef:ChangeDetectorRef,
              readonly wpFiltersService:WorkPackageFiltersService) {
    super();
    this.visible$ = this.wpFiltersService.observeUntil(componentDestroyed(this));
  }

  ngOnInit():void {
    this.wpTableFilters
      .pristine$()
      .pipe(
        this.untilDestroyed()
      )
      .subscribe(() => {
        this.filters = this.wpTableFilters.current;
        this.loaded = true;
        this.cdRef.detectChanges();
      });
  }

  public replaceIfComplete(filters:QueryFilterInstanceResource[]) {
    this.wpTableFilters.replaceIfComplete(filters);
    this.filtersChanged.emit(this.filters);
  }
}
