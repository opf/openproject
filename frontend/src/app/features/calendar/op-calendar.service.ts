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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ElementRef, Injectable, inject } from '@angular/core';
import { Subject } from 'rxjs';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';
import moment from 'moment-timezone';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { DayHeaderContentArg } from '@fullcalendar/core';

@Injectable()
export class OpCalendarService extends UntilDestroyedMixin {
  readonly weekdayService = inject(WeekdayService);
  readonly dayService = inject(DayResourceService);
  readonly configurationService = inject(ConfigurationService);

  resize$ = new Subject<void>();

  resizeObs:ResizeObserver;

  resizeObserver(v:ElementRef<HTMLElement>|undefined):void {
    if (!v) {
      return;
    }

    if (!this.resizeObs) {
      this.resizeObs = new ResizeObserver(() => this.resize$.next());
    }

    this.resizeObs.observe(v.nativeElement);
  }

  applyNonWorkingDay({ date }:{ date?:Date }, nonWorkingDays:IDay[]):string[] {
    const utcDate = moment(date).utc();
    const formatted = utcDate.format('YYYY-MM-DD');
    if (date && (this.weekdayService.isNonWorkingDay(utcDate) || nonWorkingDays.find((el) => el.date === formatted))) {
      return ['fc-non-working-day'];
    }
    return [];
  }

  dayHeaderContent(event:DayHeaderContentArg):string {
    // When the user did not configure a custom date format, we can always return the default content for the
    // fullcalendar day header.
    if (!this.configurationService.dateFormatPresent()) {
      return event.text;
    }

    // Additionally, we must use the default in dayGridMonth view, as it displays the day of the week:
    if (event.view.type === 'dayGridMonth') {
      return event.text;
    }

    // We are not in month grid view and there is a date format configured => return a formatted date according to
    // the settings. Prefix the day of the week name for better readability.
    const configuredDateFormat = this.configurationService.dateFormat();
    const formatWithoutYear = this.stripYearFromDateFormat(configuredDateFormat);
    const utcDate = moment(event.date).utc();

    return utcDate.format(`ddd ${formatWithoutYear}`);
  }

  stripYearFromDateFormat(format:string):string {
    return format.replace(/(\/|-|,?\s?)Y{3,4}$/, '').replace(/^Y{4}-/, '');
  }
}
