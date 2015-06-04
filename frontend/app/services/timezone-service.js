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

module.exports = function(ConfigurationService, I18n) {
  var TimezoneService = {

    setupLocale: function() {
      moment.locale(I18n.locale);
    },

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
      var d = TimezoneService.parseDatetime(datetimeString);
      return d.format(TimezoneService.getDateFormat()) + ' ' +
        d.format(TimezoneService.getTimeFormat());
    },

    formattedISODate: function(date) {
      return TimezoneService.parseDate(date).format('YYYY-MM-DD');
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
    }
  };

  return TimezoneService;
};
