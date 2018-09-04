//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

import {Injectable} from '@angular/core';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import * as moment from 'moment-timezone';
import {Moment} from 'moment';

@Injectable()
export class TimezoneService {
  constructor(readonly ConfigurationService:ConfigurationService,
              readonly I18n:I18nService) {
    this.setupLocale();
  }

  public setupLocale() {
    moment.locale(I18n.locale);
  }

  /**
   * Takes a utc date time string and turns it into
   * a local date time moment object.
   */
  public parseDatetime(datetime:string, format?:string):Moment {
    var d = moment.utc(datetime, format);

    if (this.ConfigurationService.isTimezoneSet()) {
      d.local();
      d.tz(this.ConfigurationService.timezone());
    }

    return d;
  }

  public parseDate(date:string, format?:string) {
    return moment(date, format);
  }

  /**
   * Parses a string that is considered to be a local date and
   * turns it into a utc date time moment object.
   * 'Local' might mean the browsers default time zone or the one configured
   * in the Configuration Service.
   *
   * @param {String} date
   * @param {String} format
   * @returns {Moment}
   */
  public parseLocalDateTime(date:string, format?:string) {
    var result;
    format = format || this.getTimeFormat();

    if (this.ConfigurationService.isTimezoneSet()) {
      result = moment.tz(date, format!, this.ConfigurationService.timezone());
    } else {
      result = moment(date, format);
    }
    result.utc();

    return result;
  }

  /**
   * Parses the specified datetime and applies the user's configured timezone, if any.
   *
   * This will effectfully transform the [server] provided datetime object to the user's configured local timezone.
   *
   * @param {String} datetime in 'YYYY-MM-DDTHH:mm:ssZ' format
   * @returns {Moment}
   */
  public parseISODatetime(datetime:string) {
    return this.parseDatetime(datetime, 'YYYY-MM-DDTHH:mm:ssZ');
  }

  public parseISODate(date:string) {
    return this.parseDate(date, 'YYYY-MM-DD');
  }

  public formattedDate(date:string) {
    var d = this.parseDate(date);
    return d.format(this.getDateFormat());
  }

  /**
   * Return whether the date is in the past
   * @param dateString
   */
  public inThePast(dateString:string):boolean {
    return this.daysFromToday(dateString) <= -1;
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

  public formattedTime(datetimeString:string) {
    return this.parseDatetime(datetimeString).format(this.getTimeFormat());
  }

  public formattedDatetime(datetimeString:string) {
    var c = this.formattedDatetimeComponents(datetimeString);
    return c[0] + ' ' + c[1];
  }

  public formattedDatetimeComponents(datetimeString:string) {
    var d = this.parseDatetime(datetimeString);
    return [
      d.format(this.getDateFormat()),
      d.format(this.getTimeFormat())
    ];
  }

  public toHours(durationString:string) {
    return Number(moment.duration(durationString).asHours().toFixed(2));
  }

  public formattedDuration(durationString:string) {
    return this.I18n.t('js.units.hour', {count: this.toHours(durationString)});
  }

  public formattedISODate(date:any) {
    return this.parseDate(date).format('YYYY-MM-DD');
  }

  public formattedISODateTime(datetime:any) {
    return datetime.format();
  }

  public isValidISODate(date:any) {
    return this.isValid(date, 'YYYY-MM-DD');
  }

  public isValidISODateTime(dateTime:string) {
    return this.isValid(dateTime, 'YYYY-MM-DDTHH:mm:ssZ');
  }

  public isValid(date:string, dateFormat:string) {
    var format = dateFormat || this.getDateFormat();
    return moment(date, [format], true).isValid();
  }

  public getDateFormat() {
    return this.ConfigurationService.dateFormatPresent() ? this.ConfigurationService.dateFormat() : 'L';
  }

  public getTimeFormat() {
    return this.ConfigurationService.timeFormatPresent() ? this.ConfigurationService.timeFormat() : 'LT';
  }
}
