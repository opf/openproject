//-- copyright
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
//++

import {ChangeDetectionStrategy, Component, Input, OnChanges, OnInit, Output, ViewChild} from '@angular/core';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {QueryFilterResource} from 'core-app/modules/hal/resources/query-filter-resource';
import {DebouncedEventEmitter} from 'core-components/angular/debounced-event-emitter';
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";
import {BannersService} from "core-app/modules/common/enterprise/banners.service";
import {NgSelectComponent} from "@ng-select/ng-select";
import {WorkPackageViewFiltersService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import {WorkPackageFiltersService} from "core-components/filters/wp-filters/wp-filters.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {componentDestroyed} from "@w11k/ngx-componentdestroyed";

const ADD_FILTER_SELECT_INDEX = -1;


@Component({
  selector: 'query-filters',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './query-filters.component.html'
})
export class QueryFiltersComponent extends UntilDestroyedMixin implements OnInit, OnChanges {

  @ViewChild(NgSelectComponent) public ngSelectComponent:NgSelectComponent;
  @Input() public filters:QueryFilterInstanceResource[];
  @Input() public showCloseFilter:boolean = false;
  @Output() public filtersChanged = new DebouncedEventEmitter<QueryFilterInstanceResource[]>(componentDestroyed(this));


  public remainingFilters:any[] = [];
  public eeShowBanners:boolean = false;
  public focusElementIndex:number = 0;
  public trackByName = AngularTrackingHelpers.trackByName;

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

  constructor(readonly wpTableFilters:WorkPackageViewFiltersService,
              readonly wpFiltersService:WorkPackageFiltersService,
              readonly I18n:I18nService,
              readonly bannerService:BannersService) {
    super();
  }

  ngOnInit() {
    this.eeShowBanners = this.bannerService.eeShowBanners;
  }

  ngOnChanges() {
    this.updateRemainingFilters();
  }

  public onFilterAdded(filterToBeAdded:QueryFilterResource) {
    if (filterToBeAdded) {
      let newFilter = this.wpTableFilters.instantiate(filterToBeAdded);
      this.filters.push(newFilter);

      const index = this.currentFilterLength();
      this.updateFilterFocus(index);
      this.updateRemainingFilters();

      this.filtersChanged.emit(this.filters);
      this.ngSelectComponent.clearItem(filterToBeAdded);
    }
  }

  public closeFilter() {
    this.wpFiltersService.toggleVisibility();
  }

  public isHiddenFilter(filter:QueryFilterResource) {
    return _.includes(this.wpTableFilters.hidden, filter.id);
  }

  public deactivateFilter(removedFilter:QueryFilterInstanceResource) {
    let index = this.filters.indexOf(removedFilter);
    _.remove(this.filters, f => f.id === removedFilter.id);

    this.filtersChanged.emit(this.filters);

    this.updateFilterFocus(index);
    this.updateRemainingFilters();
  }

  public get isSecondSpacerVisible():boolean {
    const hasSearch = !!_.find(this.filters, (f) => f.id === 'search');
    const hasAvailableFilter = !!_.find(this.filters, (f) => f.id !== 'search' && this.isFilterAvailable(f.id));

    return hasSearch && hasAvailableFilter;
  }

  private updateRemainingFilters() {
    this.remainingFilters = _.sortBy(this.wpTableFilters.remainingVisibleFilters(this.filters), 'name');
  }

  private updateFilterFocus(index:number) {
    var activeFilterCount = this.currentFilterLength();

    if (activeFilterCount === 0) {
      this.focusElementIndex = ADD_FILTER_SELECT_INDEX;
    } else {
      const filterIndex = (index < activeFilterCount) ? index : activeFilterCount - 1;
      const filter = this.currentFilterAt(filterIndex);
      this.focusElementIndex = this.filters.indexOf(filter);
    }
  }

  public currentFilterLength() {
    return this.filters.length;
  }

  public currentFilterAt(index:number) {
    return this.filters[index];
  }

  public isFilterAvailable(id:string):boolean {
    return (this.wpTableFilters.availableFilters.some(filter => filter.id === id));
  }

  public onOpen() {
    setTimeout(() => {
      const component = this.ngSelectComponent as any;
      if (component && component.dropdownPanel) {
        component.dropdownPanel._updatePosition();
      }
    }, 25);
  }
}
