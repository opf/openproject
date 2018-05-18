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

import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {Component, Inject, Input, OnDestroy, Output} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {DebouncedEventEmitter} from 'core-components/angular/debounced-event-emitter';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';

@Component({
  selector: 'filter-string-value',
  template: require('!!raw-loader!./filter-string-value.component.html')
})
export class FilterStringValueComponent implements OnDestroy {
  @Input() public filter:QueryFilterInstanceResource;
  @Output() public filterChanged = new DebouncedEventEmitter<QueryFilterInstanceResource>(componentDestroyed(this));

  readonly text = {
    enter_text: this.I18n.t('js.work_packages.description_enter_text')
  };

  constructor(@Inject(I18nToken) readonly I18n:op.I18n) {
  }

  ngOnDestroy() {
    // Nothing to do, added for interface compatibility
  }

  public get value() {
    return this.filter.values[0];
  }

  public set value(val) {
    this.filter.values[0] = val || '';
    this.filterChanged.emit(this.filter);
  }
}
