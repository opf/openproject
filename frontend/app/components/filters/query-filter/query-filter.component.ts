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

import {WorkPackageTableFiltersService} from '../../wp-fast-table/state/wp-table-filters.service';
import {Component, EventEmitter, Inject, Input, OnDestroy, OnInit, Output} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import WorkPackageFiltersService from 'core-components/filters/wp-filters/wp-filters.service';
import {QueryFilterResource} from 'core-components/api/api-v3/hal-resources/query-filter-resource.service';
import {AngularTrackingHelpers} from 'core-components/angular/tracking-functions';

@Component({
  selector: '[query-filter]',
  template: require('!!raw-loader!./query-filter.component.html')
})
export class QueryFilterComponent implements OnInit, OnDestroy {
  @Input() public filter:QueryFilterResource;
  @Output() public filterChanged = new EventEmitter<QueryFilterResource>();
  @Output() public deactivateFilter = new EventEmitter<QueryFilterResource>();

  public availableOperators:any;
  public showValuesInput:boolean = false;
  public eeShowBanners:boolean = false;
  public trackByHref = AngularTrackingHelpers.halHref;
  public compareByHref = AngularTrackingHelpers.compareByHref;

  public text = {
    open_filter: this.I18n.t('js.filter.description.text_open_filter'),
    close_filter: this.I18n.t('js.filter.description.text_close_filter'),
    label_filter_add: this.I18n.t('js.work_packages.label_filter_add'),
    upsale_for_more: this.I18n.t('js.filter.upsale_for_more'),
    upsale_link: this.I18n.t('js.filter.upsale_link'),
    button_delete: this.I18n.t('js.button_delete'),
  };

  constructor(readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly wpFiltersService:WorkPackageFiltersService,
              @Inject(I18nToken) readonly I18n:op.I18n) {
  }

  public onFilterUpdated(filter:QueryFilterResource) {
    this.filter = filter;
    this.showValuesInput = this.filter.currentSchema.isValueRequired();
    this.filterChanged.emit(this.filter);
  }

  public removeThisFilter() {
    this.deactivateFilter.emit(this.filter);
  }

  ngOnInit() {
    this.eeShowBanners = angular.element('body').hasClass('ee-banners-visible');
    this.availableOperators = this.filter.schema.availableOperators;
    this.showValuesInput = this.filter.currentSchema.isValueRequired();
  }

  ngOnDestroy() {
    // Nothing to do
  }
}

