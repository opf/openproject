//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

module.exports = function(ConfigurationService, I18n) {
  var TimezoneService = {

    setupLocale: function() {
      moment.locale(I18n.locale);
    },

    /**
     * Takes a utc date time string and turns it into
     * a local date time moment object.
     */
    parseDatetime: function(datetime, format) {
      var d = moment.utc(datetime, format);

      if (ConfigurationService.isTimezoneSet()) {
        d.local();
        d.tz(ConfigurationService.timezone());
      }

      return d;
    },

    parseDate: function(date, format) {
      return moment(date, format);
    },

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
    parseLocalDateTime: function(date, format) {
      var result;

      if (ConfigurationService.isTimezoneSet()) {
        result = moment.tz(date, format, ConfigurationService.timezone());
      } else {
        result = moment(date, format);
      }
      result.utc();

      return result;
    },

    /**
     * Parses the specified datetime and applies the user's configured timezone, if any.
     *
     * This will effectfully transform the [server] provided datetime object to the user's configured local timezone.
     *
     * @param {String} datetime in 'YYYY-MM-DDTHH:mm:ssZ' format
     * @returns {Moment}
     */
    parseISODatetime: function(datetime) {
      return this.parseDatetime(datetime, 'YYYY-MM-DDTHH:mm:ssZ');
    },

    parseISODate: function(date) {
      return TimezoneService.parseDate(date, 'YYYY-MM-DD');
    },

    formattedDate: function(date) {
      var d = TimezoneService.parseDate(date);
      return d.format(TimezoneService.getDateFormat());
    },

    formattedTime: function(datetimeString) {
      return TimezoneService.parseDatetime(datetimeString).format(TimezoneService.getTimeFormat());
    },

    formattedDatetime: function(datetimeString) {
      var c = TimezoneService.formattedDatetimeComponents(datetimeString);
      return c[0] + ' ' + c[1];
    },

    formattedDatetimeComponents: function(datetimeString) {
      var d = TimezoneService.parseDatetime(datetimeString);
      return [
        d.format(TimezoneService.getDateFormat()),
        d.format(TimezoneService.getTimeFormat())
      ];
    },

    toHours: function(durationString) {
      return Number(moment.duration(durationString).asHours().toFixed(2));
    },

    formattedDuration: function(durationString) {
      return I18n.t('js.units.hour', { count: TimezoneService.toHours(durationString) });
    },

    formattedISODate: function(date) {
      return TimezoneService.parseDate(date).format('YYYY-MM-DD');
    },

    formattedISODateTime: function(datetime) {
      return datetime.format();
    },

    isValidISODate: function(date) {
      return TimezoneService.isValid(date, 'YYYY-MM-DD');
    },

    isValidISODateTime: function(dateTime) {
      return TimezoneService.isValid(dateTime, 'YYYY-MM-DDTHH:mm:ssZ');
    },

    isValid: function(date, dateFormat) {
      var format = dateFormat || (ConfigurationService.dateFormatPresent() ?
                   ConfigurationService.dateFormat() : 'L');
      return moment(date, [format], true).isValid();
    },


    getDateFormat: function() {
      return ConfigurationService.dateFormatPresent() ? ConfigurationService.dateFormat() : 'L';
    },

    getTimeFormat: function() {
      return ConfigurationService.timeFormatPresent() ? ConfigurationService.timeFormat() : 'LT';
    }
  };

  return TimezoneService;
};
