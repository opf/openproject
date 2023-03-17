// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { Moment } from 'moment';
import {
  HostBinding,
  Component,
  Input,
  OnInit,
  Output,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DebouncedEventEmitter } from 'core-app/shared/helpers/rxjs/debounced-event-emitter';
import { componentDestroyed } from '@w11k/ngx-componentdestroyed';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { AbstractDateTimeValueController } from '../abstract-filter-date-time-value/abstract-filter-date-time-value.controller';

@Component({
  selector: 'op-filter-date-times-value',
  templateUrl: './filter-date-times-value.component.html',
})
export class FilterDateTimesValueComponent extends AbstractDateTimeValueController implements OnInit {
  @HostBinding('id') get id() {
    return `div-values-${this.filter.id}`;
  }

  @HostBinding('class.inline-label') className = true;

  @Input() public shouldFocus = false;

  @Input() public filter:QueryFilterInstanceResource;

  @Output() public filterChanged = new DebouncedEventEmitter<QueryFilterInstanceResource>(componentDestroyed(this));

  readonly text = {
    spacer: this.I18n.t('js.filter.value_spacer'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly timezoneService:TimezoneService,
  ) {
    super(I18n, timezoneService);
  }

  public get value():string[] {
    return (this.filter.values as string[]) || [];
  }

  public set value(val:string[]) {
    this.filter.values = val;
    this.filterChanged.emit(this.filter);
  }

  public get begin():HalResource|string {
    return this.filter.values[0];
  }

  public get end() {
    return this.filter.values[1];
  }

  public get lowerBoundary():Moment|null {
    if (this.begin && this.timezoneService.isValidISODateTime(this.begin.toString())) {
      return this.timezoneService.parseDatetime(this.begin.toString());
    }
    return null;
  }

  public get upperBoundary():Moment|null {
    if (this.end && this.timezoneService.isValidISODateTime(this.end.toString())) {
      return this.timezoneService.parseDatetime(this.end.toString());
    }
    return null;
  }

  public parser(data:string[]):string[] {
    if (data.length === 2) {
      let [start, end] = data.map((el) => this.timezoneService.parseISODatetime(el));
      start = start.startOf('day');
      end = end.endOf('day');

      return [start, end].map((el) => this.timezoneService.formattedISODateTime(el));
    }

    return data.map((date) => this.isoDateParser(date));
  }

  public formatter(data:string[]):string[] {
    return data.map((date) => this.isoDateFormatter(date));
  }
}
