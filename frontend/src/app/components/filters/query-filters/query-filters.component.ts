//-- copyright
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
//++

import {WorkPackageTableFiltersService} from '../../wp-fast-table/state/wp-table-filters.service';
import {WorkPackageFiltersService} from "../../filters/wp-filters/wp-filters.service";
import {Component, Inject, Input, OnChanges, OnDestroy, OnInit, Output} from '@angular/core';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {WorkPackageTableFilters} from 'core-components/wp-fast-table/wp-table-filters';
import {QueryFilterResource} from  'core-app/modules/hal/resources/query-filter-resource';
import {DebouncedEventEmitter} from 'core-components/angular/debounced-event-emitter';
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";

const ADD_FILTER_SELECT_INDEX = -1;


@Component({
  selector: 'query-filters',
  templateUrl: './query-filters.component.html'
})
export class QueryFiltersComponent implements OnInit, OnChanges, OnDestroy {

  @Input() public filters:WorkPackageTableFilters;
  @Input() public showCloseFilter:boolean = false;
  @Output() public filtersChanged = new DebouncedEventEmitter<WorkPackageTableFilters>(componentDestroyed(this));


  public filterToBeAdded:QueryFilterResource|undefined;
  public remainingFilters:any[] = [];
  public eeShowBanners:boolean = false;
  public focusElementIndex:number = 0;
  public compareByName = AngularTrackingHelpers.trackByName;

  public text = {
    open_filter: this.I18n.t('js.filter.description.text_open_filter'),
    label_filter_add: this.I18n.t('js.work_packages.label_filter_add'),
    close_filter: this.I18n.t('js.filter.description.text_close_filter'),
    upsale_for_more: this.I18n.t('js.filter.upsale_for_more'),
    upsale_link: this.I18n.t('js.filter.upsale_link'),
    close_form: this.I18n.t('js.close_form_title'),
    selected_filter_list: this.I18n.t('js.label_selected_filter_list'),
    button_delete: this.I18n.t('js.button_delete'),
    please_select: this.I18n.t('js.placeholders.selection'),
    filter_by_text: this.I18n.t('js.work_packages.label_filter_by_text')
  };

  constructor(readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly wpFiltersService:WorkPackageFiltersService,
              readonly I18n:I18nService) {
  }

  ngOnInit() {
    this.eeShowBanners = jQuery('body').hasClass('ee-banners-visible');

    this.filters.current.forEach((filter:QueryFilterInstanceResource) => {
      if (!this.isFilterAvailable(filter.id)) {
        this.filters.remove(filter);
      }
    });
  }

  ngOnDestroy() {
    // Nothing to do.
  }

  ngOnChanges() {
    this.updateRemainingFilters();
  }

  public onFilterAdded(filterToBeAdded:QueryFilterResource) {
    if (filterToBeAdded) {
      let newFilter = this.filters.add(filterToBeAdded);
      this.filterToBeAdded = undefined;

      const index = this.currentFilterLength();
      this.updateFilterFocus(index);
      this.updateRemainingFilters();

      this.filtersChanged.emit(this.filters);
    }
  }

  public closeFilter() {
    this.wpFiltersService.toggleVisibility();
  }

  public isHiddenFilter(filter:QueryFilterResource) {
    return _.includes(this.filters.hidden, filter.id);
  }

  public deactivateFilter(removedFilter:QueryFilterInstanceResource) {
    let index = this.filters.current.indexOf(removedFilter);

    this.filters.remove(removedFilter);
    if (removedFilter.isCompletelyDefined()) {
      this.filtersChanged.emit(this.filters);
    }

    this.updateFilterFocus(index);
    this.updateRemainingFilters();
  }

  public get isSecondSpacerVisible():boolean {
    return _.reject(this.filters.current, (filter) => {
      return (filter.id === 'search');
    }).length > 0;
  }

  private updateRemainingFilters() {
    this.remainingFilters = _.sortBy(this.filters.remainingVisibleFilters, 'name');
  }

  private updateFilterFocus(index:number) {
    var activeFilterCount = this.currentFilterLength();

    if (activeFilterCount === 0) {
      this.focusElementIndex = ADD_FILTER_SELECT_INDEX;
    } else {
      const filterIndex = (index < activeFilterCount) ? index : activeFilterCount - 1;
      const filter = this.currentFilterAt(filterIndex);
      this.focusElementIndex = this.filters.current.indexOf(filter);
    }
  }

  public currentFilterLength() {
    return this.filters.current.length;
  }

  public currentFilterAt(index:number) {
    return this.filters.current[index];
  }

  public isFilterAvailable(id:string):boolean {
    return (this.filters.availableFilters.some(filter => filter.id === id));
  }
}
