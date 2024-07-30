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

import { Injectable } from '@angular/core';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import * as moment from 'moment-timezone';
import { Moment } from 'moment';
import { outputChronicDuration } from '../../shared/helpers/chronic_duration';

@Injectable({ providedIn: 'root' })
export class TimezoneService {
  constructor(
    readonly configurationService:ConfigurationService,
    readonly I18n:I18nService,
  ) { }

  /**
   * Returns the user's configured timezone or guesses it through moment
   */
  public userTimezone():string {
    return this.configurationService.isTimezoneSet() ? this.configurationService.timezone() : moment.tz.guess();
  }

  /**
   * Takes a utc date time string and turns it into
   * a local date time moment object.
   */
  public parseDatetime(datetime:string, format?:string):Moment {
    return moment
      .utc(datetime, format)
      .tz(this.userTimezone());
  }

  public parseDate(date:Date|string, format?:string):Moment {
    return moment(date, format);
  }

  /**
   * Parses the specified datetime and applies the user's configured timezone, if any.
   *
   * This will effectfully transform the [server] provided datetime object to the user's configured local timezone.
   *
   * @param {String} datetime in 'YYYY-MM-DDTHH:mm:ssZ' format
   * @returns {Moment}
   */
  public parseISODatetime(datetime:string):Moment {
    return this.parseDatetime(datetime, 'YYYY-MM-DDTHH:mm:ssZ');
  }

  public parseISODate(date:string):Moment {
    return this.parseDate(date, 'YYYY-MM-DD');
  }

  public formattedDate(date:string, format = this.getDateFormat()):string {
    const d = this.parseDate(date);
    return d.format(format);
  }

  /**
   * Returns the number of days from today the given dateString is apart.
   * Negative means the date lies in the past.
   * @param dateString
   */
  public daysFromToday(dateString:string):number {
    const date = this.parseDate(dateString);
    const today = moment().startOf('day');

    return date.diff(today, 'days');
  }

  public formattedTime(datetimeString:string, format?:string):string {
    return this.parseDatetime(datetimeString).format(format || this.getTimeFormat());
  }

  public formattedDatetime(datetimeString:string):string {
    const c = this.formattedDatetimeComponents(datetimeString);
    return `${c[0]} ${c[1]}`;
  }

  public formattedRelativeDateTime(datetimeString:string):string {
    const d = this.parseDatetime(datetimeString);
    return d.fromNow();
  }

  public formattedDatetimeComponents(datetimeString:string):string[] {
    const d = this.parseDatetime(datetimeString);
    return [
      d.format(this.getDateFormat()),
      d.format(this.getTimeFormat()),
    ];
  }

  public toSeconds(durationString:string):number {
    return Number(moment.duration(durationString).asSeconds().toFixed(2));
  }

  public toHours(durationString:string):number {
    return Number(moment.duration(durationString).asHours().toFixed(2));
  }

  public toDays(durationString:string):number {
    return Number(moment.duration(durationString).asDays().toFixed(2));
  }

  public toISODuration(input:string|number, unit:'hours'|'days'):string {
    return moment.duration(input, unit).toISOString();
  }

  public formattedDuration(durationString:string, unit:'hour'|'days' = 'hour'):string {
    switch (unit) {
      case 'hour':
        return this.I18n.t('js.units.hour', {
          count: this.toHours(durationString),
        });
      case 'days':
        return this.I18n.t('js.units.day', {
          count: this.toDays(durationString),
        });
      default:
        // Case fallthrough for eslint
        return '';
    }
  }

  public formattedChronicDuration(durationString:string, opts = {
    format: this.configurationService.durationFormat(),
    hoursPerDay: this.configurationService.hoursPerDay(),
    daysPerMonth: this.configurationService.daysPerMonth(),
  }):string {
    // Keep in sync with app/services/duration_converter#output
    const seconds = this.toSeconds(durationString);

    return outputChronicDuration(seconds, opts) || '0h';
  }

  public formattedISODate(date:any):string {
    return this.parseDate(date).format('YYYY-MM-DD');
  }

  public formattedISODateTime(datetime:any):string {
    return datetime.format();
  }

  public isValidISODate(date:any):boolean {
    return this.isValid(date, 'YYYY-MM-DD');
  }

  public isValidISODateTime(dateTime:string):boolean {
    return this.isValid(dateTime, 'YYYY-MM-DDTHH:mm:ssZ');
  }

  public isValid(date:string, dateFormat:string):boolean {
    const format = dateFormat || this.getDateFormat();
    return moment(date, [format], true).isValid();
  }

  public getDateFormat():string {
    return this.configurationService.dateFormatPresent() ? this.configurationService.dateFormat() : 'L';
  }

  public getTimeFormat():string {
    return this.configurationService.timeFormatPresent() ? this.configurationService.timeFormat() : 'LT';
  }
}
