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

import {QueryFilterInstanceResource} from '../../api/api-v3/hal-resources/query-filter-instance-resource.service';
import {Component, Inject, Input, OnDestroy, Output} from '@angular/core';
import {I18nToken, TimezoneServiceToken} from 'core-app/angular4-transition-utils';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {DebouncedEventEmitter} from 'core-components/angular/debounced-event-emitter';

@Component({
  selector: 'filter-dates-value',
  template: require('!!raw-loader!./filter-dates-value.component.html')
})
export class FilterDatesValueComponent implements OnDestroy {
  @Input() public filter:QueryFilterInstanceResource;
  @Output() public filterChanged = new DebouncedEventEmitter<QueryFilterInstanceResource>(componentDestroyed(this));

  readonly text = {
    spacer: this.I18n.t('js.filter.value_spacer')
  };

  constructor(@Inject(TimezoneServiceToken) readonly TimezoneService:any,
              @Inject(I18nToken) readonly I18n:op.I18n) {
  }

  ngOnDestroy() {
    // Nothing to do, added for interface compatibility
  }

  public get begin() {
    return this.filter.values[0];
  }

  public set begin(val) {
    this.filter.values[0] = val || '';
    this.filterChanged.emit(this.filter);
  }

  public get end() {
    return this.filter.values[1];
  }

  public set end(val) {
    this.filter.values[1] = val || '';
    this.filterChanged.emit(this.filter);
  }

  public parser(data:any) {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      return data;
    } else {
      return null;
    }
  }

  public formatter(data:any) {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      var d = this.TimezoneService.parseDate(data);
      return this.TimezoneService.formattedISODate(d);
    } else {
      return null;
    }
  }
}
