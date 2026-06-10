//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, Input, HostBinding, OnInit, Output } from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { DebouncedEventEmitter } from 'core-app/shared/helpers/rxjs/debounced-event-emitter';
import { Moment } from 'moment';
import { componentDestroyed } from '@w11k/ngx-componentdestroyed';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { AbstractDateTimeValueController } from '../abstract-filter-date-time-value/abstract-filter-date-time-value.controller';

@Component({
  selector: 'op-filter-date-time-value',
  templateUrl: './filter-date-time-value.component.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class FilterDateTimeValueComponent extends AbstractDateTimeValueController implements OnInit {
  @HostBinding('id') get id() {
    return `div-values-${this.filter.id}`;
  }

  @HostBinding('class.inline-label') className = true;

  @Input() public shouldFocus = false;

  @Input() public filter:QueryFilterInstanceResource;

  @Output() public filterChanged = new DebouncedEventEmitter<QueryFilterInstanceResource>(componentDestroyed(this));

  public get value():HalResource|string {
    return this.filter.values[0];
  }

  public set value(val) {
    this.filter.values = [val as string]; // eslint-disable-line @typescript-eslint/no-unnecessary-type-assertion
    this.filterChanged.emit(this.filter);
  }

  public get valueString() {
    return this.filter.values[0].toString();
  }

  public get lowerBoundary():Moment|null {
    if (this.value && this.timezoneService.isValidISODateTime(this.valueString)) {
      return this.timezoneService.parseDatetime(this.valueString);
    }

    return null;
  }

  public get upperBoundary():Moment|null {
    if (this.value && this.timezoneService.isValidISODateTime(this.valueString)) {
      return this.timezoneService.parseDatetime(this.valueString).add(24, 'hours');
    }

    return null;
  }
}
