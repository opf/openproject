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

import {Component, EventEmitter, Input, Output} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';

@Component({
  selector: 'filter-boolean-value',
  templateUrl: './filter-boolean-value.component.html'
})
export class FilterBooleanValueComponent {
  @Input() public shouldFocus:boolean = false;
  @Input() public filter:QueryFilterInstanceResource;
  @Output() public filterChanged = new EventEmitter<QueryFilterInstanceResource>();

  public text = {
    placeholder: this.I18n.t('js.placeholders.selection'),
    true: this.I18n.t('js.general_text_Yes'),
    false: this.I18n.t('js.general_text_No')
  };

  constructor(readonly I18n:I18nService) {
  }

  public get value():HalResource | string {
    return this.filter.values[0];
  }

  public set value(val) {
    this.filter.values[0] = val;
    this.filterChanged.emit(this.filter);
  }

  public get hasNoValue() {
    return _.isEmpty(this.filter.values);
  }

  public get availableOptions() {
    return [true, false];
  }
}
