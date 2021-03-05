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

import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { QueryFilterResource } from 'core-app/modules/hal/resources/query-filter-resource';
import { AngularTrackingHelpers } from 'core-components/angular/tracking-functions';
import { QueryFilterInstanceResource } from "core-app/modules/hal/resources/query-filter-instance-resource";
import { BannersService } from "core-app/modules/common/enterprise/banners.service";
import { WorkPackageViewFiltersService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";
import { CurrentProjectService } from 'core-app/components/projects/current-project.service';

@Component({
  selector: '[query-filter]',
  templateUrl: './query-filter.component.html'
})
export class QueryFilterComponent implements OnInit {
  @Input() public shouldFocus = false;
  @Input() public filter:QueryFilterInstanceResource;
  @Output() public filterChanged = new EventEmitter<QueryFilterResource>();
  @Output() public deactivateFilter = new EventEmitter<QueryFilterResource>();

  public availableOperators:any;
  public showValuesInput = false;
  public eeShowBanners = false;
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

  constructor(readonly wpTableFilters:WorkPackageViewFiltersService,
              readonly schemaCache:SchemaCacheService,
              readonly I18n:I18nService,
              readonly currentProject:CurrentProjectService,
              readonly bannerService:BannersService) {
  }

  public onFilterUpdated(filter:QueryFilterInstanceResource) {
    this.filter = filter;
    this.showValuesInput = this.showValues(this.filter);
    this.filterChanged.emit(this.filter);
  }

  public removeThisFilter() {
    this.deactivateFilter.emit(this.filter);
  }

  public get valueType():string|undefined {
    if (this.filter.currentSchema && this.filter.currentSchema.values) {
      return this.filter.currentSchema.values.type;
    }

    return undefined;
  }

  ngOnInit() {
    this.eeShowBanners = this.bannerService.eeShowBanners;
    this.availableOperators = this.schemaCache.of(this.filter).availableOperators;
    this.showValuesInput = this.showValues(this.filter);
  }

  private showValues(filter:QueryFilterInstanceResource) {
    return  this.filter.currentSchema!.isValueRequired() && this.filter.currentSchema!.values!.type !== '[1]Boolean';
  }
}
