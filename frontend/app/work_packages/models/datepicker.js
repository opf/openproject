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

module.exports = function(TimezoneService, ConfigurationService) {
  var datepickerFormat = 'yy-mm-dd';

  function Datepicker(datepickerElem, date, options) {
    this.date = date;
    this.datepickerCont = angular.element(datepickerElem);
    this.datepickerInstance = null;
    this.initialize(options);
  }

  Datepicker.prototype.initialize = function(options) {
    var self = this,
        firstDayOfWeek = ConfigurationService.startOfWeekPresent() ?
          ConfigurationService.startOfWeek() :
          jQuery.datepicker._defaults.firstDay;

    var mergedOptions = angular.extend({}, options, {
      firstDay: firstDayOfWeek,
      showWeeks: true,
      changeMonth: true,
      changeYear: true,
      dateFormat: datepickerFormat,
      defaultDate: TimezoneService.formattedISODate(self.date),
      inline: true,
      showButtonPanel: true
    });

    this.datepickerInstance = this.datepickerCont.datepicker(mergedOptions);
  };

  Datepicker.prototype.clear = function() {
    this.datepickerInstance.datepicker('setDate' , null);
  };

  Datepicker.prototype.hide = function() {
    this.datepickerInstance.datepicker('hide');
  };

  Datepicker.prototype.show = function() {
    this.datepickerInstance.datepicker('show');
  };

  return Datepicker;
};

