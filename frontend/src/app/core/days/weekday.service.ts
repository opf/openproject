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

import {
  Injectable,
  Injector,
} from '@angular/core';
import * as moment from 'moment';
import {
  take,
  tap,
} from 'rxjs/operators';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { WeekdayResourceService } from 'core-app/core/state/days/weekday.service';
import { IWeekday } from 'core-app/core/state/days/weekday.model';
import {
  Observable,
  of,
} from 'rxjs';
import { Moment } from 'moment';

@Injectable({ providedIn: 'root' })
export class WeekdayService {
  @InjectField() weekdaysService:WeekdayResourceService;

  private weekdays:IWeekday[];

  constructor(
    readonly injector:Injector,
  ) {}

  /**
   * @param date The iso day number (1-7) or a date instance
   * @return {boolean} whether the given iso day is working or not
   */
  public isNonWorkingDay(date:Moment|Date|number):boolean {
    const isoDayOfWeek = (typeof date === 'number') ? date : moment(date).isoWeekday();
    return !!(this.weekdays || []).find((wd) => wd.day === isoDayOfWeek && !wd.working);
  }

  public get nonWorkingDays():IWeekday[] {
    return this.weekdays.filter((day) => !day.working);
  }

  loadWeekdays():Observable<IWeekday[]> {
    if (this.weekdays) {
      return of(this.weekdays);
    }

    return this
      .weekdaysService
      .requireCollection()
      .pipe(
        take(1),
        tap((weekdays) => {
          this.weekdays = weekdays;
        }),
      );
  }
}
