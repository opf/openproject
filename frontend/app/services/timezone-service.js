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

    parseDatetime: function(datetime, format) {
      return moment.utc(datetime, format).local().tz(ConfigurationService.timezone());
    },

    parseDate: function(date, format) {
      return moment(date, format);
    },

    /**
     * Parses a string that is considered to be a local date, which is considered to be in local time
     * applies the user's configured timezone to it.
     *
     * @param {String} date
     * @param {String} format
     * @returns {Moment}
     */
    parseLocalDate: function(date, format) {
      return moment.tz(date, format || 'YYYY-MM-DD', ConfigurationService.timezone())
    },

    /**
     * @param {String} datetime in 'YYYY-MM-DDTHH:mm:ssZ' format
     * @returns {Moment}
     */
    parseISODatetime: function(datetime) {
      return TimezoneService.parseDatetime(datetime, 'YYYY-MM-DDTHH:mm:ssZ');
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

    formattedISODatetime: function(datetime) {
      return datetime.format('YYYY-MM-DDTHH:mm:ssZ');
    },

    isValidISODate: function(date) {
      return TimezoneService.isValid(date, 'YYYY-MM-DD');
    },

    isValid: function(date, dateFormat) {
      var format = dateFormat || (ConfigurationService.dateFormatPresent() ?
                   ConfigurationService.dateFormat() : 'L');
      return moment(date, [format]).isValid();
    },

    getDateFormat: function() {
      return ConfigurationService.dateFormatPresent() ? ConfigurationService.dateFormat() : 'L';
    },

    getTimeFormat: function() {
      return ConfigurationService.timeFormatPresent() ? ConfigurationService.timeFormat() : 'LT';
    },

    getTimezoneNG: function() {
      var now = moment.utc().tz(ConfigurationService.timezone());
      return now.format('ZZ');
    }
  };

  return TimezoneService;
};
